extends Node

var current_player_index = -1

func _ready() -> void:
	# Get first alive player, and enable its camera
	for player_data in Game.players:
		var player = player_data.instance as Player
		if player and not player.is_dead():
			player.camera_2d.enabled = true
			current_player_index = player_data.index


func disable() -> void:
	for player_data in Game.players:
		var player = player_data.instance as Player
		if player:
			player.camera_2d.enabled = false


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("move_right"):
		next()
	if Input.is_action_just_pressed("move_left"):
		prev()


func next() -> void:
	var next_index = (current_player_index + 1) % Game.players.size()
	while next_index != current_player_index:
		var player_data = Game.players[next_index]
		var player = player_data.instance as Player
		if player and not player.is_dead():
			var current_player = Game.players[current_player_index].instance as Player
			if current_player:
				current_player.camera_2d.enabled = false
			player.camera_2d.enabled = true
			current_player_index = player_data.index
			break
		next_index = (next_index + 1) % Game.players.size()


func prev() -> void:
	var prev_index = (current_player_index - 1 + Game.players.size()) % Game.players.size()
	while prev_index != current_player_index:
		var player_data = Game.players[prev_index]
		var player = player_data.instance as Player
		if player and not player.is_dead():
			var current_player = Game.players[current_player_index].instance as Player
			if current_player:
				current_player.camera_2d.enabled = false
			player.camera_2d.enabled = true
			current_player_index = player_data.index
			break
		prev_index = (prev_index - 1 % Game.players.size()) % Game.players.size()
