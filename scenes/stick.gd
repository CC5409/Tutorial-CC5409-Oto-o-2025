extends Node2D

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		rotation = global_position.direction_to(get_global_mouse_position()).angle()

func setup(player_data: Statics.PlayerData):
	set_multiplayer_authority(player_data.id, false)
	multiplayer_synchronizer.set_multiplayer_authority(player_data.id)
