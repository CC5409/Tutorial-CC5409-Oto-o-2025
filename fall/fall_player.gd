@tool
class_name FallPlayer
extends HBoxContainer


enum PieceType {
	O
}

func get_piece_type_color(piece_type) -> Color:
	match piece_type:
		PieceType.O:
			return Color.BLUE
	return Color.WHITE

class PieceSegment:
	var coord: Vector2i
	var type: PieceType
	
	func _init(x, y, new_type) -> void:
		coord = Vector2i(x, y)
		type = new_type


@export var width := 10:
	set(value):
		width = value
		make_board()
@export var height := 20:
	set(value):
		height = value
		make_board()
@export var slot_scene: PackedScene


var board
var falling_piece: Array[PieceSegment]:
	set(value):
		draw_piece(falling_piece, false)
		falling_piece = value
		draw_piece(falling_piece, true)
var piece_type: PieceType


@onready var grid: GridContainer = %Grid
@onready var label: Label = $VBoxContainer/Label


func _ready() -> void:
	make_board()


func make_board() -> void:
	for child in grid.get_children():
		child.queue_free()
	grid.columns = width + 2
	for j in height + 2:
		for i in width + 2:
			var slot_inst = slot_scene.instantiate() as FallSlot
			grid.add_child(slot_inst)
			var is_border = i == 0 or i == width + 1 or j == 0 or j == height + 1
			slot_inst.color = Color.GRAY if is_border else Color.BLACK
	board = []
	for i in width:
		var row = []
		row.resize(height)
		row.fill(false)
		board.push_back(row)


func setup(player_data: Statics.PlayerData):
	label.text = player_data.name
	name = str(player_data.id)
	set_multiplayer_authority(player_data.id, false)
	#input_synchronizer.set_multiplayer_authority(player_data.id)

func start_game() -> void:
	piece_type = get_piece_type()
	falling_piece = spawn_piece(piece_type)


func get_piece_type() -> PieceType:
	return PieceType.O

func spawn_piece(piece_type: PieceType) -> Array[PieceSegment]:
	match piece_type:
		PieceType.O:
			var left = (width - 2) / 2
			return [
				PieceSegment.new(left, 0, piece_type),
				PieceSegment.new(left + 1, 0, piece_type),
				PieceSegment.new(left, 1, piece_type),
				PieceSegment.new(left + 1, 1, piece_type),
			]
	return []


func draw_piece(piece: Array[PieceSegment], draw: bool) -> void:
	for segment in piece:
		var slot: FallSlot = grid.get_child((segment.coord.y + 1) * (width + 2) + segment.coord.x + 1) 
		slot.color = get_piece_type_color(segment.type)
