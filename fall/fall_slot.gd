@tool
class_name FallSlot
extends TextureRect

@export var color: Color:
	set(value):
		color = value
		var shader_material = material as ShaderMaterial
		if shader_material:
			shader_material.set_shader_parameter("color", color)
