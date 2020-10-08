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
	Color(0.0, 1.0, 1.0), Color(0.0, 0.3, 0.3), Color(0.5, 0.0, 0.5), Color(0.7, 0.7, 0.0), Color(0.9, 0.0, 0.9)
]

signal players_number_changed
signal connected_ok

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
	players[id] = player_name
	# si es el jugador servidor llamamos a start_game
	if get_tree().is_network_server():
		start_game()

func _player_disconnected(id : int) -> void:
	# borramos el jugador desconectado
	players.erase(id)
	emit_signal("players_number_changed")

func _connected_ok() -> void:
	emit_signal("connected_ok")

func _server_disconnected() -> void:
	# TODO: gestionar desconexiones
	pass

func _connected_fail() -> void:
	# TODO: gestionar errores de conexion
	pass
	
remote func register_player(user_name : String):
	# Obtenemos el id del rpc sender
	var id : int = get_tree().get_rpc_sender_id()
	# Store the info
	players[id] = user_name
	emit_signal("players_number_changed")

func start_game() -> void:
	# variables a hacer cargar
	var spawn_players : Dictionary = {}
	# jugador local
	spawn_players[get_tree().get_network_unique_id()] = {
		index = 1,
		name = player_name
	}
	# jugadores remotos
	for player in players:
		spawn_players[player] = {
			index = spawn_players.size() + 1,
			name = players[player]
		}
	for player in spawn_players:
		# llamamos al configure game para cada peer
		rpc_id(player, "configure_game", spawn_players)
	# llamamos a configure game en el servidor
	configure_game(spawn_players)

remote func configure_game(spawn_players : Dictionary) -> void:
	# cargamos el mundo
	var world : Node = get_node("/root/World")
	if world == null:
		world = load("res://Scenes/World/World.tscn").instance()
		get_node("/root").add_child(world)
		get_node("/root/Lobby/Control").hide()
	# numero de posicion
	var position_index : int = 1
	# recorremos los jugadores
	for n_id in spawn_players:
		# agregamos el jugador al juego
		add_player_to_game(n_id, position_index)
		position_index +=1
	# agregamos el numero de jugadores
	world.set_players_number(spawn_players.size())
	# ocultamos el boton de start del lobby si no es la conexion servidor
	if !get_tree().is_network_server():
		world.hide_start()

func add_player_to_game(n_id : int, position_index : int) -> void:
	# cargamos el mundo
	var world : Node = get_node("/root/World")
	# si el jugador ya existiese en la partida local salimos de la funcion
	var player : KinematicBody2D = world.get_node("Players/" + str(n_id))
	if player != null:
		return
	# instanciamos al jugador
	player = preload("res://Scenes/Player/Player.tscn").instance()
	# instanciamos la camara
	var camera : Camera2D = preload("res://Scenes/Camera/Camera.tscn").instance()
	player.set_name(str(n_id))
	# agregar network master
	player.set_network_master(n_id)
	# es network master
	if get_tree().get_network_unique_id() == n_id:
		player.set_player_name(player_name)
		# agregamos la camara
		player.add_child(camera)
	else:
		player.set_player_name(players[n_id])
	# posicion de spawn
	var spawn_pos : Position2D = world.get_node("SpawnPosition/Position2D" + str(position_index))
	player.position = spawn_pos.position
	# mascara
	player.set_collision_mask(2 * position_index)
	# color
	player.set_color(modulate_colors[position_index - 1])
	# agregar el jugador al mundo
	world.get_node("Players").add_child(player)
