extends Node

onready var players_number : Label   = $CanvasLayer/Control/HBoxContainer/PlayersNumberLabel
onready var start_button   : Button  = $CanvasLayer/Control/HBoxContainer/StartGameButton

func set_players_number(value : int) -> void:
	# cambiamos el numero de jugadores
	players_number.text = "Jugadores " + str(value) + "/10"

func hide_start() -> void:
	# ocultamos boton de start
	start_button.hide()


func _on_StartGameButton_pressed() -> void:
	# ocultamos el boton
	start_button.hide()
	# TODO:  Generar mapa para partida (siguiente video?????)
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
	rpc("send_impostors", impostors)
	# enviamos los impostores al usuario local
	send_impostors(impostors)
	
remote func send_impostors(impostors : Array) -> void:
	# recorremos los impostores
	for n_id in impostors:
		# enviamos el valor de impostor
		var player : KinematicBody2D = get_node("Players/" + n_id)
		player.set_impostor(true, impostors.has(str(get_tree().get_network_unique_id())))
