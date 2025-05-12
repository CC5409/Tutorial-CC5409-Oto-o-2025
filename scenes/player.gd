class_name Player
extends CharacterBody2D

signal enemy_spawn_requested
signal grenade_spawn_requested
signal death_requested

@export var max_speed = 400
@export var acceleration = 600
@export var bullet_scene: PackedScene

@onready var label: Label = $Label
@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree["parameters/playback"]
@onready var pivot: Node2D = $Pivot
@onready var input_synchronizer: InputSynchronizer = $InputSynchronizer
@onready var sync_timer: Timer = $SyncTimer
@onready var camera_2d: ShakingCamera = $Camera2D
@onready var gun: Gun = %Gun
@onready var stick: Node2D = $Stick
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var hud: MarginContainer = $CanvasLayer/HUD

#logica del player b

func _ready() -> void:
	health_component.health_changed.connect(func(value): health_bar.value = value)
	health_bar.value = health_component.health
	health_component.died.connect(_on_died)
	Game.coins_changed.connect(_on_coins_changed)
	hud.set_coins(0)

func _physics_process(delta: float) -> void:
	var move_input = input_synchronizer.move_input
	velocity = velocity.move_toward(move_input * max_speed, acceleration * delta)
	
	if is_multiplayer_authority():
		if input_synchronizer.fire_pressed:
			input_synchronizer.fire_pressed = false
			#camera_2d.shake()
			gun.fire_pressed()
		elif input_synchronizer.fire_released:
			input_synchronizer.fire_released = false
			gun.fire_released()
		
		
		
	if move_input.x:
		pivot.scale.x = sign(move_input.x)
	
	move_and_slide()
	
	# animations
	if move_input:
		playback.travel("run")
	else:
		playback.travel("idle")
	if is_multiplayer_authority():
		pass
		# animation things
		# send_animation.rpc


func _input(event: InputEvent) -> void:
	if is_multiplayer_authority():
		if event.is_action_pressed("test"):
			test.rpc(1)
		if event.is_action_pressed("spawn"):
			request_spawn.rpc_id(1, get_global_mouse_position())
		if event.is_action_pressed("grenade"):
			request_grenade.rpc_id(1, get_global_mouse_position())


func setup(player_data: Statics.PlayerData):
	label.text = player_data.name
	name = str(player_data.id)
	self_modulate = Color.RED if player_data.role == Statics.Role.ROLE_A else Color.BLUE
	set_multiplayer_authority(player_data.id, false)
	input_synchronizer.set_multiplayer_authority(player_data.id)
	gun.setup(player_data)
	camera_2d.enabled = is_multiplayer_authority()
	hud.visible = is_multiplayer_authority()
	if is_multiplayer_authority():
		sync_timer.timeout.connect(_on_sync)
		sync_timer.start()
	stick.setup(player_data)

@rpc("authority", "call_local", "unreliable_ordered")
func test(meh):
	Debug.log("test %s" % [label.text], 10)


@rpc("unreliable_ordered")
func send_data(pos: Vector2, vel: Vector2) -> void:
	position = lerp(position, pos, 0.5)
	velocity = velocity.lerp(vel, 0.5)


@rpc("call_local")
func fire(spawn_position: Vector2):
	Debug.log("fire")
	var bullet_inst = bullet_scene.instantiate()
	bullet_inst.global_position = spawn_position
	multiplayer_spawner.add_child(bullet_inst, true)

func _on_sync() -> void:
	send_data.rpc(position, velocity)


func take_damage(damage: int) -> void:
	Debug.log("%s took %d damage" % [name, damage])

@rpc("any_peer", "call_local", "reliable")
func request_spawn(pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
	enemy_spawn_requested.emit(pos)


@rpc("any_peer", "call_local", "reliable")
func request_grenade(pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var player_data = Game.get_player(get_multiplayer_authority())
	grenade_spawn_requested.emit(pos, player_data.role)

func _on_died() -> void:
	if multiplayer.is_server():
		death_requested.emit()


func is_dead() -> bool:
	return health_component.health == 0


func _on_coins_changed() -> void:
	if is_multiplayer_authority():
		var player = Game.get_current_player()
		hud.set_coins(player.coins)

func attack() -> void:
	Debug.log("Player attack")
