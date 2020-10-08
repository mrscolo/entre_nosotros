extends KinematicBody2D

# velocidad del jugador
export var speed : int = 150

# variable remota con la posicion y movimiento del jugador
remotesync var remote_info : Dictionary = {
	direction = Vector2.ZERO,
	position = Vector2.ZERO,
	animation = "idle"
}

func set_player_name(value : String) -> void:
	# setear nombre de jugador
	$Label.text = value

func set_color(value : Color) -> void:
	# setear color del jugador
	$AnimatedSprite.modulate = value

func _physics_process(delta : float) -> void:
	# direccion
	var direction : Vector2 = Vector2.ZERO
	# animacion
	var animation : String = "idle"
	# si es la conexion maestra comprobamos el movimiento segun Input
	if is_network_master():
		direction = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
		).normalized()
		# si esta en movimiento asignamos la animacion de correr
		if direction != Vector2.ZERO:
			animation = "running"
		# sincronizamos la variable remota
		rset_unreliable("remote_info", {
			direction = direction,
			position = self.position,
			animation = animation
		})
	else: # no es conexion maestra y el personaje es controlador por un jugador remoto
		# asignamos los valores desde la variable remota
		direction = remote_info.direction
		self.position = remote_info.position
		animation = remote_info.animation
	# asignamos la animacion
	if $AnimatedSprite.animation != animation:
		$AnimatedSprite.play(animation)
	# modificamos el flip para mirar a izquierda o derecha segun corresponda
	if direction.x < 0:
		$AnimatedSprite.flip_h = true
	elif direction.x > 0:
		$AnimatedSprite.flip_h = false
	# movemos el personaje
	move_and_slide(direction * speed)
