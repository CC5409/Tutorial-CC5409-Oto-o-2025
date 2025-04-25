extends Node2D

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		rotation = global_position.direction_to(get_global_mouse_position()).angle()
