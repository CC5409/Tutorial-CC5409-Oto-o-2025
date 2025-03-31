extends CharacterBody2D

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
@onready var gun: Node2D = $Gun
@onready var camera_2d: Camera2D = $Camera2D


func _physics_process(delta: float) -> void:
	var move_input = input_synchronizer.move_input
	velocity = velocity.move_toward(move_input * max_speed, acceleration * delta)
	
	if input_synchronizer.fire:
		input_synchronizer.fire = false
		if is_multiplayer_authority():
			gun.fire.rpc_id(1, get_global_mouse_position())
		
		
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


func setup(player_data: Statics.PlayerData):
	label.text = player_data.name
	name = str(player_data.id)
	self_modulate = Color.RED if player_data.role == Statics.Role.ROLE_A else Color.BLUE
	set_multiplayer_authority(player_data.id, false)
	input_synchronizer.set_multiplayer_authority(player_data.id)
	gun.setup(player_data)
	camera_2d.enabled = is_multiplayer_authority()
	if is_multiplayer_authority():
		sync_timer.timeout.connect(_on_sync)
		sync_timer.start()

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
