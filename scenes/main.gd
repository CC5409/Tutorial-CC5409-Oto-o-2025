extends Node2D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

@onready var players: Node2D = $Players
@onready var markers: Node2D = $Markers
@onready var enemies: Node2D = $Enemies
@onready var tile_map_layer: TileMapLayer = $TileMapLayer


func _ready() -> void:
	for i in Game.players.size():
		var player = Game.players[i]
		var player_inst = player_scene.instantiate()
		players.add_child(player_inst)
		player_inst.setup(player)
		player_inst.global_position = markers.get_child(i).global_position
		if multiplayer.is_server():
			player_inst.enemy_spawn_requested.connect(_on_enemy_spawn_requested)
	if multiplayer.is_server():
		Game.enemies_changed.connect(_on_enemies_changed)


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
	var enemy_inst = enemy_scene.instantiate()
	enemy_inst.global_position = pos
	enemies.add_child(enemy_inst, true)
