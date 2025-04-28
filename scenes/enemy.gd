class_name Enemy
extends CharacterBody2D

signal drop_requested

@export var max_speed = 200
@export var drop_scene: PackedScene

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var path_target_timer: Timer = $PathTargetTimer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_2d_hurtbox: CollisionShape2D = $Hurtbox/CollisionShape2D



func _ready() -> void:
	Game.enemies += 1
	health_component.health_changed.connect(update_health_bar)
	update_health_bar(health_component.health)
	health_component.died.connect(_death)
	hurtbox.damage_taken.connect(take_damage)
	if multiplayer.is_server():
		navigation_agent.velocity_computed.connect(_on_velocity_computed) 
		path_target_timer.timeout.connect(func(): set_movement_target(get_global_mouse_position()))

func _physics_process(delta):
	if not multiplayer.is_server():
		return
	# Do not query when the map has never synchronized and is empty.
	if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if navigation_agent.is_navigation_finished():
		return

	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * max_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
	#send_pos.rpc(global_position)

func take_damage() -> void:
	pass
	#Debug.log("%s took damage" % [name])
	#take_damage_fx.rpc()


@rpc("reliable", "call_local")
func take_damage_fx() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_EXPO)
	tween\
		.parallel()\
		.tween_property(sprite_2d, "scale", Vector2.ONE * 1.2, 0.1).\
		set_ease(Tween.EASE_OUT).\
		set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	tween\
		.parallel()\
		.tween_property(sprite_2d, "scale", Vector2.ONE, 0.2)


func update_health_bar(value: float) -> void:
	health_bar.value = value


func set_movement_target(movement_target: Vector2):
	navigation_agent.set_target_position(movement_target)

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()


@rpc("unreliable_ordered")
func send_pos(pos) -> void:
	global_position = pos


func _death() -> void:
	if drop_scene:
		drop_requested.emit(drop_scene, global_position)
	set_physics_process(false)
	collision_shape_2d.set_deferred("disabled", true)
	collision_shape_2d_hurtbox.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1)
	animation_player.play("death")
	await animation_player.animation_finished
	await get_tree().create_timer(2).timeout
	queue_free()
	Game.enemies -= 1
