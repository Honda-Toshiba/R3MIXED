class_name WeaponBeam
extends Sprite3D

var weapon: Weapon

func _process(delta: float) -> void:
	global_position = get_parent().global_position

func set_color_by_rarity(w: Weapon) -> void:
	# Store reference to weapon it's attached to, used by other scripts
	weapon = w
	
	modulate = w.get_color()
	return
