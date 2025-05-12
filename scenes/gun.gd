class_name Gun
extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 2
@export var mode: Weapon.GunMode

var time_of_last_shot: int = 0


@onready var bullet_spawner: MultiplayerSpawner = $BulletSpawner
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var bullet_spawn: Marker2D = $BulletSpawn
@onready var full_auto_timer: Timer = $FullAutoTimer

func _ready() -> void:
	full_auto_timer.timeout.connect(fire)
	full_auto_timer.wait_time = 1 / fire_rate


func setup(player_data: Statics.PlayerData):
	set_multiplayer_authority(player_data.id, false)
	multiplayer_synchronizer.set_multiplayer_authority(player_data.id)
	if bullet_scene:
		bullet_spawner.add_spawnable_scene(bullet_scene.resource_path)

func fire_pressed() -> void:
	Debug.log("fire_pressed")
	if not is_multiplayer_authority():
		return
	match mode:
		Weapon.GunMode.SEMI_AUTO:
			fire()
		Weapon.GunMode.FULL_AUTO:
			fire()
			full_auto_timer.start()
		Weapon.GunMode.BURST:
			pass


func fire_released() -> void:
	Debug.log("fire_released")
	if not is_multiplayer_authority():
		return
	match mode:
		Weapon.GunMode.SEMI_AUTO:
			pass
		Weapon.GunMode.FULL_AUTO:
			full_auto_timer.stop()
		Weapon.GunMode.BURST:
			pass


func fire() -> void:
	if time_of_last_shot + 1000 / fire_rate < Time.get_ticks_msec():
		time_of_last_shot = Time.get_ticks_msec()
		var target = get_global_mouse_position()
		fire_server.rpc_id(1, target)


@rpc("call_local", "reliable")
func fire_server(target: Vector2) -> void:
	if not multiplayer.is_server():
		return
	if not bullet_scene:
		return
	var bullet_inst = bullet_scene.instantiate()
	bullet_inst.global_position = bullet_spawn.global_position
	bullet_inst.global_rotation = global_rotation
	bullet_spawner.add_child(bullet_inst, true)
