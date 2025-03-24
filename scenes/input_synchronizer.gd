class_name InputSynchronizer
extends MultiplayerSynchronizer

@export var move_input: Vector2
@export var fire: bool

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if Input.is_action_just_pressed("fire"):
			trigger_fire.rpc()


@rpc("call_local", "reliable")
func trigger_fire():
	fire = true
