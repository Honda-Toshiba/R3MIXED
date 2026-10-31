class_name WeaponBeam
extends Sprite3D

@export var gradient: Gradient

func set_color_by_rarity(w: Weapon) -> void:
	var r_head = w.head.rarity
	var r_tail = w.tail.rarity
	
	var r = max(r_head, r_tail)
	var t := inverse_lerp(1.0, 5.0, r) # normalizes 1-5 range into 0-1
	var color := gradient.sample(t)
	
	modulate = color
	return
