class_name ItemCard
extends Node

@export var background: CanvasItem
@export var weapon_name: RichTextLabel 
@export var stats_head: RichTextLabel
@export var stats_tail: RichTextLabel

func display_weapon(w: Weapon) -> void:
	background.modulate = w.get_color()
	weapon_name.text = "[font=res://assets/fonts/font_cute.ttf][font_size=150][color=#" \
						+ w.rarity_to_color(w.head.rarity).to_html() + "]" + w.head.name +  " [color=#" \
						+ w.rarity_to_color(w.tail.rarity).to_html() + "]" + w.tail.name
	return
