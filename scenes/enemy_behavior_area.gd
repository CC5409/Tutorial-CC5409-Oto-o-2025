extends Area2D

@export var enemy_target: Enemy.FollowTarget


func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	var enemy = body as Enemy
	if enemy:
		enemy.follow_target = enemy_target
