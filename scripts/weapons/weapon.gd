class_name Weapon
extends Resource

@export var id: StringName = &""
@export var name: String = ""
@export var head: WeaponPart
@export var tail: WeaponPart

static func create_drop(head_pool: Array[WeaponPart], tail_pool: Array[WeaponPart], odds: Array[int]) -> Weapon:
	# Validate
	assert(odds.size() == 5, "Enemy drop odds array is not of length 5.")
	
	var acc = 0
	for n in odds:
		acc += n
	if acc != 100:
		push_error("Enemy drop odds do not add up to 100.")
		return
	
	# Choose parts
	var luck_head := randi_range(1, 100)
	var luck_tail := randi_range(1, 100)
	var rarity_head = 0
	var rarity_tail = 0
	
	var r = 5
	var min = 100
	
	while r > 0:
		if rarity_head != 0 and rarity_tail != 0:
			break
			
		min -= odds[r - 1]
		if luck_head > min and rarity_head == 0:
			rarity_head = r
		if luck_tail > min and rarity_tail == 0:
			rarity_tail = r
			
		r -= 1
	
	var heads = head_pool.filter(func(p): return p.rarity == rarity_head)
	var tails = tail_pool.filter(func(p): return p.rarity == rarity_tail)
	
	if heads.is_empty() or tails.is_empty():
		push_error("Enemy has a nonzero chance for a rarity that's empty in its head/tail drop pool.")
		return
	
	# Compose weapon
	var weapon := Weapon.new()
	weapon.head = heads.pick_random()
	weapon.tail = tails.pick_random()
	
	var crypto := Crypto.new()
	var bytes := crypto.generate_random_bytes(4)
	var token := bytes.hex_encode()
	weapon.id = token
	
	weapon.name = weapon.head.name + " " + weapon.tail.name
	
	return weapon

static func build_model(w: Weapon) -> Node3D:
	if w.head == null or w.tail == null:
		push_warning("Cannot build weapon with a null part.")
		return null
	
	var root := Node3D.new()
	root.name = "weapon_inst_" + w.id 
	
	var head := w.head.model.instantiate() as Node3D
	var tail := w.tail.model.instantiate() as Node3D
	root.add_child(head)
	root.add_child(tail)
	
	var link_head := head.get_node_or_null("link_head") as Node3D
	var link_tail := tail.get_node_or_null("link_tail") as Node3D
	if link_head == null or link_tail == null:
		push_warning("Weapon built but one or more of its parts does not define a link point.")
		return root 
	
	tail.transform = head.transform * link_head.transform * link_tail.transform.affine_inverse()
	return root
	
