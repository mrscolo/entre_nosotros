extends Node

onready var name_edit   : LineEdit = $Control/Panel/VBoxContainer/HBoxContainer/Name
onready var ip_edit     : LineEdit = $Control/Panel/VBoxContainer/HBoxContainer2/IP
onready var error_label : Label    = $Control/Panel/VBoxContainer/ErrorLabel
onready var host_button : Button   = $Control/Panel/VBoxContainer/HBoxContainer3/HostButton
onready var join_button : Button   = $Control/Panel/VBoxContainer/HBoxContainer3/JoinButton
onready var item_list   : ItemList = $Control/Panel/VBoxContainer/ItemList

func _ready() -> void:
	# cargamos el usuario por defecto
	name_edit.text = OS.get_environment("USERNAME")
	# cargamos la animacion de load
	$AnimationPlayer.play("load")
	# conectamos a las signal de la clase singleton
	Online.connect("connected_ok", self, "_on_connected_ok")
	Online.connect("players_number_changed", self, "_on_players_number_changed")

func _on_connected_ok() -> void:
	# ocultamos botones
	host_button.hide()
	join_button.hide()

func _on_players_number_changed() -> void:
	# refrescamos lobby
	refresh_lobby()
	
	var world : Node = get_node("/root/World")
	if world == null:
		return
	# si el mundo esta cargado en local, cambiamos el numero de jugadores conectados
	world.set_players_number(Online.players.size() + 1)

func _on_HostButton_pressed() -> void:
	# Comprobamos que existe nombre
	if name_edit.text == "":
		error_label.text = "Introduce un nombre"
		return
	# comprobamos que la ip es valida
	if !ip_edit.text.is_valid_ip_address():
		error_label.text = "Introduce una IP valida"
		return
	error_label.text = ""
	# Ocultamos los botones
	host_button.hide()
	join_button.hide()
	# Creamos la partida
	Online.create_game(name_edit.text)
	# refrescamos lobby
	refresh_lobby()
	# asignamos la animacion de transicion
	$AnimationPlayer.play("transition")
	# comenzamos el juego
	Online.start_game()


func _on_JoinButton_pressed() -> void:
	# Nos unimos a la partida
	$AnimationPlayer.play("transition")
	Online.join_game(name_edit.text, ip_edit.text)

func refresh_lobby() -> void:
	# Vacio la lista
	item_list.clear()
	# Agrego el player local
	item_list.add_item(Online.player_name + " (YOU)")
	# Agrego los players remotos
	for player in Online.players.values():
		item_list.add_item(player)
