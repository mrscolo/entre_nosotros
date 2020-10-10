extends Camera2D


func disable_lights() -> void:
	$Light2D.hide()
	$Light2DMask.hide()
