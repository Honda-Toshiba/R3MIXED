class_name ItemCard
extends Node

@export var weapon_name: RichTextLabel 
@export var stats_head: RichTextLabel
@export var stats_tail: RichTextLabel

func display_weapon(w: Weapon) -> void:
	weapon_name.text = "[font=res://assets/fonts/font_cute.ttf][font_size=220]" + w.name
	return
