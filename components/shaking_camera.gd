class_name ShakingCamera
extends Camera2D


func shake(force: float = 5, duration: float = 0.2, steps: int = 6) -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	var step_duration = duration / (steps + 1) 
	for i in steps:
		tween.tween_property(self, "offset", _get_random_vector(force), step_duration)
	tween.tween_property(self, "offset", Vector2.ZERO, step_duration)


func _get_random_vector(size: float) -> Vector2:
	return Vector2.RIGHT.rotated(randf_range(0, 2 * PI)) * size
