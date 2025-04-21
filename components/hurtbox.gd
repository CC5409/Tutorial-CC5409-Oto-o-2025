class_name Hurtbox
extends Area2D

signal damage_taken

@export var health_component: HealthComponent

func _ready() -> void:
	#if is_multiplayer_authority():
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var hitbox = area as Hitbox
	if hitbox:
		if is_multiplayer_authority():
			if health_component:
				health_component.take_damage(hitbox.damage)
				hitbox.damage_dealt.emit()
				damage_taken.emit()
		if owner.has_method("take_damage_fx"):
			owner.take_damage_fx()
