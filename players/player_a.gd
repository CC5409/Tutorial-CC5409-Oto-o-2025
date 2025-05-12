class_name PlayerA
extends Player

func _ready() -> void:
	super._ready()
	Debug.log("I'm player A")


func attack() -> void:
	super.attack()
	Debug.log("Player A attack")
