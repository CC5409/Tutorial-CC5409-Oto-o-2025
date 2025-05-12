extends Node2D

@export var enemy_scene: PackedScene
@export var spectator_scene: PackedScene
@export var grenade_scene: PackedScene
@export var respawn_time: float = 5.0
@export var player_scenes: Dictionary[Statics.Role, PackedScene]
@export var fallback_player_scene: PackedScene

var spectator


@onready var players: Node2D = $Players
@onready var markers: Node2D = $Markers
@onready var enemies: Node2D = $Enemies
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen
@onready var paint_layer: TileMapLayer = $PaintLayer
@onready var grenade_spawner: MultiplayerSpawner = $GrenadeSpawner
@onready var respawn_screen: PanelContainer = %RespawnScreen


func _ready() -> void:
	respawn_screen.hide()
	
	for i in Game.players.size():
			var player = Game.players[i]
			spawn_player(player.id, markers.get_child(i).global_position)
	if multiplayer.is_server():
		Game.enemies_changed.connect(_on_enemies_changed)
	game_over_screen.hide()
	if grenade_scene:
		grenade_spawner.add_spawnable_scene(grenade_scene.resource_path)

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


func _on_grenade_spawn_requested(pos: Vector2, role: Statics.Role) -> void:
	if not grenade_scene:
		return
	var coords = paint_layer.local_to_map(paint_layer.to_local(pos))
	Debug.log(coords)
	var position = paint_layer.to_global(paint_layer.map_to_local(coords))
	var grenade_inst = grenade_scene.instantiate()
	grenade_inst.position = position
	grenade_inst.role = role
	grenade_inst.coords = coords
	grenade_inst.exploded.connect(_on_grenade_exploded)
	add_child(grenade_inst)
	

func _on_grenade_exploded(coords: Vector2i, role: Statics.Role) -> void:
	# runs on server
	if not multiplayer.is_server():
		return
	grenade_explosion.rpc(coords, role)


@rpc("reliable", "call_local")
func grenade_explosion(coords: Vector2i, role: Statics.Role) -> void:
	# run on each player	
	var power = 3
	paint_layer.set_cell(coords, 0, Vector2i.ZERO, get_alternative_id(role))
	for i in power:
		paint_layer.set_cell(coords + Vector2i(0, i), 0, Vector2i.ZERO, get_alternative_id(role))
		paint_layer.set_cell(coords + Vector2i(0, -i), 0, Vector2i.ZERO, get_alternative_id(role))
		paint_layer.set_cell(coords + Vector2i(i, 0), 0, Vector2i.ZERO, get_alternative_id(role))
		paint_layer.set_cell(coords + Vector2i(-i, 0), 0, Vector2i.ZERO, get_alternative_id(role))


func get_alternative_id(role: Statics.Role) -> int:
	match role:
		Statics.Role.ROLE_A:
			return 1
		Statics.Role.ROLE_B:
			return 2
		Statics.Role.ROLE_C:
			return 3
	return 0

func _on_player_death_requested(player: Player) -> void:
	kill_player.rpc(int(player.name))


@rpc("call_local", "reliable")
func kill_player(player_id: int) -> void:
	var player_data = Game.get_player(player_id)
	if player_data.instance:
		player_data.instance.queue_free()
		if player_data.instance.is_multiplayer_authority() and spectator_scene:
			spectator = spectator_scene.instantiate()
			add_child(spectator)
			show_respawn_screen()
		player_data.instance = null
	if multiplayer.is_server():
		handle_respawn(player_id)
	
	# check_game_over()

func show_respawn_screen() -> void:
	respawn_screen.show()
	respawn_screen.start(respawn_time)

# this runs on server
func handle_respawn(player_id: int) -> void:
	await get_tree().create_timer(respawn_time).timeout
	var player = Game.get_player(player_id)
	var spawn_position = markers.get_child(player.index).global_position
	spawn_player.rpc(player_id, spawn_position)



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


@rpc("call_local", "reliable")
func spawn_player(player_id: int, spawn_position: Vector2) -> void:
	var player = Game.get_player(player_id)
	Debug.log("spawning player")
	if spectator:
		spectator.disable()
		spectator.queue_free()
	respawn_screen.hide()
	var player_scene = fallback_player_scene
	if player.role in player_scenes and player_scenes[player.role]:
		player_scene = player_scenes[player.role]
	var player_inst = player_scene.instantiate() as Player
	player.instance = player_inst
	players.add_child(player_inst)
	player_inst.setup(player)
	player_inst.global_position = spawn_position
	if multiplayer.is_server():
		player_inst.enemy_spawn_requested.connect(_on_enemy_spawn_requested)
		player_inst.grenade_spawn_requested.connect(_on_grenade_spawn_requested)
		player_inst.death_requested.connect(_on_player_death_requested.bind(player_inst))
