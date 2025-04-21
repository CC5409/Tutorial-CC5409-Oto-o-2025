extends RigidBody2D



func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("fire"):
		apply_central_impulse(global_position.direction_to(get_global_mouse_position()) * 100)
