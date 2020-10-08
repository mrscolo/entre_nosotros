extends Node

onready var players_number : Label   = $CanvasLayer/Control/HBoxContainer/PlayersNumberLabel
onready var start_button   : Button  = $CanvasLayer/Control/HBoxContainer/Button

func set_players_number(value : int) -> void:
	# cambiamos el numero de jugadores
	players_number.text = "Jugadores " + str(value) + "/10"

func hide_start() -> void:
	# ocultamos boton de start
	start_button.hide()
