class_name ItemCard
extends Node

@export var background: CanvasItem
@export var head_icon: CanvasItem
@export var tail_icon: CanvasItem
@export var weapon_name: RichTextLabel 
@export var stats_head: RichTextLabel
@export var stats_tail: RichTextLabel

func display_weapon(w: Weapon) -> void:
	background.modulate = w.get_color()
	head_icon.modulate = w.rarity_to_color(w.head.rarity)
	tail_icon.modulate = w.rarity_to_color(w.tail.rarity)
	
	# Multi-color name
	#weapon_name.text = "[font=res://assets/fonts/font_cute.ttf][font_size=150][color=#" \
	#					+ w.rarity_to_color(w.head.rarity).to_html() + "]" + w.head.name +  " [color=#" \
	#					+ w.rarity_to_color(w.tail.rarity).to_html() + "]" + w.tail.name
	
	# Single-color name
	weapon_name.text = "[font=res://assets/fonts/font_cute.ttf][font_size=150][color=#" \
						+ w.get_color().to_html() + "]" + w.name

	# Part buffs/debuffs
	const BUFF_COLOR = "[color=#3aff26]"
	const DEBUFF_COLOR = "[color=#ff5252]"
	
	stats_head.text = "[font=res://assets/fonts/font_cute.ttf][font_size=90]"
	for buff in w.head.info_buffs:
		stats_head.text += BUFF_COLOR + buff + "\n"
	for debuff in w.head.info_debuffs:
		stats_head.text += DEBUFF_COLOR + debuff + "\n"
	
	stats_tail.text = "[font=res://assets/fonts/font_cute.ttf][font_size=90]"
	for buff in w.tail.info_buffs:
		stats_tail.text += BUFF_COLOR + buff + "\n"
	for debuff in w.tail.info_debuffs:
		stats_tail.text += DEBUFF_COLOR + debuff + "\n"
	
	return
