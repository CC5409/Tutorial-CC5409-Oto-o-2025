class_name InputSynchronizer
extends MultiplayerSynchronizer


@export var move_input: Vector2
@export var fire_pressed: bool
@export var fire_released: bool


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if Input.is_action_just_pressed("fire"):
			trigger_fire_pressed.rpc()
		elif Input.is_action_just_released("fire"):
			trigger_fire_released.rpc()

@rpc("call_local", "reliable")
func trigger_fire_pressed():
	fire_pressed = true


@rpc("call_local", "reliable")
func trigger_fire_released():
	fire_released = true
