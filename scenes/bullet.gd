extends Area2D

@export var max_speed = 500

func _physics_process(delta: float) -> void:
	position += max_speed * transform.x * delta
