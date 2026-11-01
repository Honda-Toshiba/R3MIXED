class_name WeaponBeam
extends Sprite3D

@export var gradient: Gradient
var weapon: Weapon

func _process(delta: float) -> void:
	global_position = get_parent().global_position

func set_color_by_rarity(w: Weapon) -> void:
	weapon = w
	
	var r_head = w.head.rarity
	var r_tail = w.tail.rarity
	
	var r = max(r_head, r_tail)
	var t := inverse_lerp(1.0, 5.0, r) # normalizes 1-5 range into 0-1
	var color := gradient.sample(t)
	
	modulate = color
	return
