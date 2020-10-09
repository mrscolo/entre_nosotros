extends Node

# puerto por defecto
const SERVER_PORT : int = 10567
# maximo numero de jugadores
const MAX_PLAYERS : int = 10

# nombre del jugador local
var player_name : String
# jugadores remotos
var players : Dictionary = {}
# array para modular el color del personaje
var modulate_colors : Array = [
	Color(1.0, 1.0, 1.0), Color(1.0, 0.0, 0.0), Color(0.0, 1.0, 0.0), Color(1.0, 1.0, 0.0), Color(1.0, 0.0, 1.0), 
	Color(0.0, 1.0, 1.0), Color(0.2, 0.1, 0.3), Color(0.2, 0.5, 0.5), Color(0.5, 0.7, 0.1), Color(0.1, 0.3, 0.9)
]
# posicion de jugadores al arrancar partida
var spawn_players : Dictionary = {}

signal players_number_changed
signal connected_ok
signal error

func create_game(user_name : String) -> void:
	# crear partida
	player_name = user_name
	var peer : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().network_peer = peer

func join_game(user_name : String, ip_address : String) -> void:
	# unirse a partida
	player_name = user_name
	var peer : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	peer.create_client(ip_address, SERVER_PORT)
	get_tree().network_peer = peer

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _player_connected(id : int) -> void:
	# registrmos jugador
	rpc_id(id, "register_player", player_name)

func _player_disconnected(id : int) -> void:
	# borramos el jugador desconectado
	if players.has(id):
		players.erase(id)
	if spawn_players.has(id):
		spawn_players.erase(id)
	rpc("remove_player_from_game", id)
	emit_signal("players_number_changed")

	
func _connected_ok() -> void:
	emit_signal("connected_ok")

func _server_disconnected() -> void:
	emit_signal("error")
	# TODO: gestionar desconexiones
	pass

func _connected_fail() -> void:
	emit_signal("error")
	# TODO: gestionar errores de conexion
	pass
	
remote func register_player(user_name : String):
	# Obtenemos el id del rpc sender
	var id : int = get_tree().get_rpc_sender_id()
	# Store the info
	players[id] = user_name
	rpc("start_game")
	emit_signal("players_number_changed")

master func start_game() -> void:
	if !spawn_players.has(get_tree().get_network_unique_id()):
		# jugador local
		spawn_players[get_tree().get_network_unique_id()] = {
			index = get_player_index(),
			name = player_name,
			color = get_player_color()
		}
	# jugadores remotos
	for player in players:
		if !spawn_players.has(player):
			spawn_players[player] = {
				index = get_player_index(),
				name = players[player],
				color = get_player_color()
			}
	for player in spawn_players:
		# llamamos al configure game para cada peer
		rpc_id(player, "configure_game", spawn_players)
	# llamamos a configure game en el servidor
	configure_game(spawn_players)

func get_player_color() -> Color:
	# buscamos un color no seleccionado
	randomize()
	while true:
		var index : int = floor(modulate_colors.size() * randf())
		var color : Color = modulate_colors[index]
		var is_used : bool = false
		for player in spawn_players.values():
			if player.color == color:
				is_used = true
				break
		if !is_used:
			return color
	return modulate_colors[0] # nunca vamos a llegar a esta instruccion

func get_player_index() -> int:
	# buscamos la posicion de aparicion del personaje
	for i in range(1, 10):
		var is_used : bool = false
		for player in spawn_players.values():
			if player.index == i:
				is_used = true
				break
		if !is_used:
			return i
	return modulate_colors[0]

remote func configure_game(spawn_players : Dictionary) -> void:
	# cargamos el mundo
	var world : Node = get_node("/root/World")
	if world == null:
		world = load("res://Scenes/World/World.tscn").instance()
		get_node("/root").add_child(world)
		get_node("/root/Lobby/Control").hide()
	# recorremos los jugadores
	for n_id in spawn_players:
		# agregamos el jugador al juego
		add_player_to_game(n_id, spawn_players[n_id])
	# agregamos el numero de jugadores
	world.set_players_number(spawn_players.size())
	# ocultamos el boton de start del lobby si no es la conexion servidor
	if !get_tree().is_network_server():
		world.hide_start()

func add_player_to_game(n_id : int, spawn_player : Dictionary) -> void:
	# cargamos el mundo
	var world : Node = get_node("/root/World")
	# si el jugador ya existiese en la partida local salimos de la funcion
	var player : KinematicBody2D = world.get_node("Players/" + str(n_id))
	if player != null:
		return
	# instanciamos al jugador
	player = preload("res://Scenes/Player/Player.tscn").instance()
	# instanciamos la camara
	var camera : Node2D = preload("res://Scenes/Camera/Camera.tscn").instance()
	player.set_name(str(n_id))
	# agregar network master
	player.set_network_master(n_id)
	# es network master
	if get_tree().get_network_unique_id() == n_id:
		# agregamos la camara
		player.add_child(camera)
	
	player.set_player_name(spawn_player.name)
	# posicion de spawn
	var spawn_pos : Position2D = world.get_node("SpawnPosition/Position2D" + str(spawn_player.index))
	player.position = spawn_pos.position
	# mascara
	player.set_collision_mask(2 * spawn_player.index)
	# color
	player.set_color( spawn_player.color)
	# agregar el jugador al mundo
	world.get_node("Players").add_child(player)
 

remotesync func remove_player_from_game(id : int) -> void:
	# eliminamos el personaje del juego
	var player : KinematicBody2D = get_node("/root/World/Players/" + str(id))
	if player == null:
		return
	get_node("/root/World/Players").remove_child(player)
