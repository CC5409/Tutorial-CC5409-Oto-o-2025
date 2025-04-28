extends Control

@export var player_scene: PackedScene

@onready var players: HBoxContainer = %Players


func _ready() -> void:
	for i in Game.players.size():
		var player = Game.players[i]
		var player_inst = player_scene.instantiate() as FallPlayer
		players.add_child(player_inst)
		player_inst.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player_inst.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		player_inst.setup(player)
	if multiplayer.is_server():
		await get_tree().create_timer(3).timeout
		start_game.rpc()

@rpc("call_local", "reliable")
func start_game() -> void:
	for player in players.get_children():
		player.start_game()
