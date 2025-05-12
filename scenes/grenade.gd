extends Node2D

@export var role: Statics.Role
@export var coords: Vector2i

signal exploded

func get_color(r: Statics.Role) -> Color:
	match r:
		Statics.Role.ROLE_A:
			return Color.RED
		Statics.Role.ROLE_B:
			return Color.BLUE
		Statics.Role.ROLE_C:
			return Color.GREEN
	return Color.MAGENTA


func _ready() -> void:
	modulate = get_color(role)
	if multiplayer.is_server():
		await get_tree().create_timer(2).timeout
		exploded.emit(coords, role)
		queue_free()
