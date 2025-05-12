extends PanelContainer

@onready var timer: Timer = $Timer
@onready var time_label: Label = %TimeLabel
@onready var bar: TextureProgressBar = %Bar

func _process(delta: float) -> void:
	bar.value = timer.wait_time - timer.time_left
	time_label.text = "%.2f" % timer.time_left

func start(value: float) -> void:
	timer.start(value)
	bar.max_value = timer.wait_time
