class_name HealthComponent
extends Node


signal died
signal health_changed(value)


@export var health: int = 100:
	set(value):
		Debug.log(value)
		if health == value:
			return
		health = clamp(value, 0 , max_health)
		health_changed.emit(health)
		if health == 0:
			died.emit()


@export var max_health: int = 100


func _ready() -> void:
	pass

func take_damage(damage: int) -> void:
	Debug.log(is_multiplayer_authority())
	health -= damage
