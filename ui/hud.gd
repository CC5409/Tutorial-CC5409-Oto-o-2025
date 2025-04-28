extends MarginContainer


@onready var coins_label: Label = %CoinsLabel


func set_coins(value: int) -> void:
	coins_label.text = str(value)
