extends Control

@onready var resume: Button = %Resume
@onready var menu: Button = %Menu
@onready var quit: Button = %Quit
@onready var pause_container: MarginContainer = %PauseContainer
@onready var player_container: MarginContainer = %PlayerContainer
@onready var player: Label = %Player

var _player


func _ready() -> void:
	quit.pressed.connect(func(): get_tree().quit())
	menu.pressed.connect(_on_menu_pressed)
	resume.pressed.connect(_on_resume_pressed)
	pause_container.hide()
	player_container.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if not get_tree().paused:
			pause.rpc()
			_player = Game.get_current_player().id
		elif _player == Game.get_current_player().id:
			unpause.rpc()
			_player = null


func _on_resume_pressed() -> void:
	unpause.rpc()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	Lobby.go_to_menu()


@rpc("any_peer", "call_local", "reliable")
func pause():
	show()
	get_tree().paused = true
	var player_id = Game.get_current_player().id
	var sender_id = multiplayer.get_remote_sender_id()
	pause_container.visible = player_id == sender_id
	player_container.visible = player_id != sender_id
	player.text = Game.get_player(sender_id).name
	

@rpc("any_peer", "call_local", "reliable")
func unpause() -> void:
	player_container.hide()
	pause_container.hide()
	get_tree().paused = false
