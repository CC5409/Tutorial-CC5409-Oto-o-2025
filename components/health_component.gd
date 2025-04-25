class_name HealthComponent
extends MultiplayerSynchronizer


signal died
signal health_changed(value)


@export var health: int = 100:
	set(value):
		if health == value:
			return
		health = clamp(value, 0 , max_health)
		health_changed.emit(health)
		if health == 0:
			died.emit()
@export var max_health: int = 100


func _init() -> void:
	replication_config.add_property("HealthComponent:health")
	replication_config.property_set_replication_mode("HealthComponent:health", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	replication_config.property_set_spawn("HealthComponent:health", true)


func take_damage(damage: int) -> void:
	health -= damage
