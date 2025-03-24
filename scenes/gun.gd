extends Node2D

@export var bullet_scene: PackedScene
@onready var bullet_spawner: MultiplayerSpawner = $BulletSpawner
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var bullet_spawn: Marker2D = $BulletSpawn


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		rotation = global_position.direction_to(get_global_mouse_position()).angle()



func setup(player_data: Statics.PlayerData):
	set_multiplayer_authority(player_data.id, false)
	multiplayer_synchronizer.set_multiplayer_authority(player_data.id)


@rpc("call_local")
func fire(mouse_position: Vector2) -> void:
	if not bullet_scene:
		return
	var bullet_inst = bullet_scene.instantiate()
	bullet_inst.global_position = bullet_spawn.global_position
	bullet_inst.global_rotation = global_rotation
	bullet_spawner.add_child(bullet_inst, true)
