extends KinematicBody2D

# velocidad del jugador
export var speed : int = 200

var is_impostor  : bool = false
var is_killable  : bool = false
var is_dead      : bool = false
var world        : Node 
var kill_timeout : int = 30

# variable remota con la posicion y movimiento del jugador
remotesync var remote_info : Dictionary = {
	direction = Vector2.ZERO,
	position = Vector2.ZERO
}

func set_impostor(value : bool, is_master_impostor : bool) -> void:
	# asignamos valor de impostor
	is_impostor = value
	# si el main es un impostor pintamos el label de rojo
	if is_impostor && is_master_impostor:
		$Label.modulate = Color(1.0 , 0.0, 0.0)

func set_world(value : Node) -> void:
	# asignamos el mundo
	world = value

func kill() -> void:
	# emitimos particulas de sangre
	$BloodParticles2D.emitting = true
	# asignamos que esta muerto
	is_dead = true
	# deshabilitamos su area de muerte
	$KillingArea2D/CollisionShape2D.disabled = true
	# deshabilitamos las colisiones
	set_collision_mask_bit(0, false)
	set_collision_layer_bit(0, false)

func set_player_name(value : String) -> void:
	# setear nombre de jugador
	$Label.text = value

func set_color(value : Color) -> void:
	# setear color del jugador
	$AnimatedSprite.modulate = value

func reset_player() -> void:
	# habilitar area para matar al jugador
	$KillingArea2D/CollisionShape2D.disabled = false
	# reseteamos variables
	is_dead     = false
	is_impostor = false
	is_killable = false

func _physics_process(delta : float) -> void:
	# si el jugador local esta vivo y el jugador remoto muerto, salimos
	if is_dead && !world.master_player.is_dead:
		if $AnimatedSprite.animation != "dead":
			$AnimatedSprite.play("dead")
		return
	# direccion
	var direction : Vector2 = Vector2.ZERO
	# si es la conexion maestra comprobamos el movimiento segun Input
	if is_network_master():
		direction = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
		).normalized()
		# sincronizamos la variable remota
		rset_unreliable("remote_info", {
			direction = direction,
			position = self.position
		})
	# si no es el jugador local, pero el jugador local es asesino, no tiene timeout activo y ademas el player es matable
	# lo matamos!
	elif world.master_player.is_impostor && world.kill_timeout == 0 && is_killable && Input.get_action_strength("ui_select") > 0:
		world.set_kill_timeout(30) # reseteamos el timeout para matar
		rpc("kill_player", get_name()) # enviamos la muerte a todos los jugadores
	else: # no es conexion maestra y el personaje es controlador por un jugador remoto
		# asignamos los valores desde la variable remota
		direction = remote_info.direction
		self.position = remote_info.position
	# asignamos la animacion
	set_animation(direction)
	# movemos el personaje
	move_and_slide(direction * speed)

func set_animation(direction : Vector2) -> void:
	# asignamos la animacion
	if !is_dead:
		if direction == Vector2.ZERO && $AnimatedSprite.animation != "idle":
			$AnimatedSprite.play("idle")
		elif direction != Vector2.ZERO && $AnimatedSprite.animation != "running":
			$AnimatedSprite.play("running")
	elif $AnimatedSprite.animation != "ghost":
		$AnimatedSprite.play("ghost")
	# modificamos el flip para mirar a izquierda o derecha segun corresponda
	if direction.x < 0:
		$AnimatedSprite.flip_h = true
	elif direction.x > 0:
		$AnimatedSprite.flip_h = false

func _on_KillingArea2D_body_entered(body : PhysicsBody2D) -> void:
	# hacemos al player remoto como matable si se dan las condiciones
	if !world.master_player.is_impostor || world.master_player != body || is_impostor:
		return
	is_killable = true

func _on_KillingArea2D_body_exited(body : PhysicsBody2D) -> void:
	# quitamos al personaje remoto como matable si se dan las condiciones
	if !world.master_player.is_impostor || world.master_player != body || is_impostor:
		return
	is_killable = false

remotesync func kill_player(id : String) -> void:
	# matamos al jugador
	world.kill_player(id)
