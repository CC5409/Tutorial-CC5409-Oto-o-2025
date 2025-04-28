extends Node2D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var spectator_scene: PackedScene

@onready var players: Node2D = $Players
@onready var markers: Node2D = $Markers
@onready var enemies: Node2D = $Enemies
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen


func _ready() -> void:
	for i in Game.players.size():
		var player = Game.players[i]
		var player_inst = player_scene.instantiate() as Player
		player.instance = player_inst
		players.add_child(player_inst)
		player_inst.setup(player)
		player_inst.global_position = markers.get_child(i).global_position
		if multiplayer.is_server():
			player_inst.enemy_spawn_requested.connect(_on_enemy_spawn_requested)
			player_inst.death_requested.connect(_on_player_death_requested.bind(player_inst))
	if multiplayer.is_server():
		Game.enemies_changed.connect(_on_enemies_changed)
	game_over_screen.hide()

func _on_enemies_changed(value: int) -> void:
	if value == 0:
		Lobby.go_to_lobby.rpc()


func _on_enemy_spawn_requested(pos: Vector2) -> void:
	var id = tile_map_layer.get_cell_source_id(tile_map_layer.local_to_map(tile_map_layer.to_local(pos)))
	#var coords = tile_map_layer.get_cell_atlas_coords(tile_map_layer.local_to_map(tile_map_layer.to_local(pos)))
	#Debug.log(id)
	#Debug.log(coords)
	
	var data = tile_map_layer.get_cell_tile_data(tile_map_layer.local_to_map(tile_map_layer.to_local(pos)))
	if not id or not data or not data.get_custom_data("navigable"):
		return

	
	tile_map_layer.tile_set
	var enemy_inst = enemy_scene.instantiate() as Enemy
	enemy_inst.global_position = pos
	enemies.add_child(enemy_inst, true)
	enemy_inst.drop_requested.connect(_on_enemy_drop_requested)
	


func _on_player_death_requested(player: Player) -> void:
	kill_player.rpc(int(player.name))


@rpc("call_local", "reliable")
func kill_player(player_id: int) -> void:
	var player_data = Game.get_player(player_id)
	if player_data.instance:
		player_data.instance.queue_free()
		if player_data.instance.is_multiplayer_authority() and spectator_scene:
			var spectator_inst = spectator_scene.instantiate()
			add_child(spectator_inst)
		player_data.instance = null
	check_game_over()


func check_game_over() -> void:
	for player_data in Game.players:
		if player_data.instance != null:
			return
	game_over_screen.show()


func _on_enemy_drop_requested(drop_scene: PackedScene, pos: Vector2) -> void:
	if drop_scene:
		var drop_inst = drop_scene.instantiate()
		add_child(drop_inst)
		drop_inst.global_position = pos
