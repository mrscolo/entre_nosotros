extends Node

onready var players_number : Label  = $CanvasLayer/Control/HBoxContainer/PlayersNumberLabel
onready var start_button   : Button = $CanvasLayer/Control/HBoxContainer/StartGameButton
onready var timeout_label  : Label  = $CanvasLayer/KillTimeoutLabel
onready var timeout_timer  : Timer  = $CanvasLayer/KillTimeoutLabel/Timer

var master_player : KinematicBody2D
var kill_timeout : int = 10

func set_master_player(value : KinematicBody2D) -> void:
	# asignamos el player local
	master_player = value
	
func set_players_number(value : int) -> void:
	# cambiamos el numero de jugadores
	players_number.text = "Jugadores " + str(value) + "/10"

func set_kill_timeout(value : int) -> void:
	# asignamos el temporizador para matar
	kill_timeout = value
	timeout_timer.start()

func hide_start() -> void:
	# ocultamos boton de start
	start_button.hide()


func _on_StartGameButton_pressed() -> void:
	# ocultamos el boton
	start_button.hide()
	# TODO:  Cambiar mapa de carga por mapa de partida, mas elaborado y con alguna mision (habra siguiente video?????)
	# ---------------------------------------------------
	# ---------------------------------------------------
	# Creamos los impostores
	var num_players : int = $Players.get_children().size()
	var num_impostors : int = 2 if num_players >= 6 else 1
	# Crearemos valores de impostor aleatorios
	randomize()
	var index_array : Array = []
	while true:
		var index : int = floor(num_players * randf())
		if index_array.has(index):
			continue
		index_array.append(index)
		if index_array.size() >= num_impostors:
			break
	# obtenemos los id de los impostores
	var impostors : Array = []
	for index in index_array:
		var player : KinematicBody2D = $Players.get_children()[index]
		impostors.append(player.name)
	# enviamos los impostores a los usuarios remotos
	rpc("config_players", impostors)
	# enviamos los impostores al usuario local
	config_players(impostors)
	# aqui tambien se podria haber utilizado un remotesync en send_impostors para evitar llamar 2 veces al procedimiento
	
remote func config_players(impostors : Array) -> void:
	# recorremos todos los jugadores
	for player in get_node("Players").get_children():
		# reseteamos las areas que pudiesen estar deshabilitadas
		player.reset_player()
	# recorremos los impostores
	for n_id in impostors:
		# enviamos el valor de impostor
		var player : KinematicBody2D = get_node("Players/" + n_id)
		player.set_impostor(true, impostors.has(str(get_tree().get_network_unique_id())))
	# si el jugador local es impostor, mostramos el temporizador de kills
	if master_player.is_impostor:
		$CanvasLayer/KillTimeoutLabel.show()
		$CanvasLayer/KillTimeoutLabel/Timer.start()

func kill_player(id_dead : String, id_killer : String) -> void:
	# matamos al jugador
	var player : KinematicBody2D = get_node("Players/" + id_dead)
	if player == null:
		return
	player.kill(id_killer)
	# si el jugador muerto es el local, deshabilitamos las luces de camara
	if player == master_player:
		var camera : Camera2D = player.get_node("Camera")
		if camera == null:
			return
		camera.disable_lights()

func _on_Timer_timeout():
	# temporizador para matar
	kill_timeout -= 1
	timeout_label.text = "Kill timeout: " + str(kill_timeout)
	if kill_timeout <= 0:
		timeout_timer.stop()
