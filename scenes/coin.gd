extends Sprite2D


func _ready() -> void:
	if multiplayer.is_server():
		Game.add_coins.rpc()
		await get_tree().create_timer(3).timeout
		queue_free()
