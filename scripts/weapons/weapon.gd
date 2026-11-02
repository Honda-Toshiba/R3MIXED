class_name Weapon
extends Resource

var id: StringName = &""
var name: String = ""
var head: WeaponPart
var tail: WeaponPart

var head_quality: float # 0.7 to 1.0, acts as multiplier to all head stats
var tail_quality: float

# Stats affected by part quality
var damage: int

const GRADIENT := preload("res://data/gradients/gradient_weapon_rarity.tres")
const BEAM := preload("res://scenes/prefabs/weapon_beam.tscn")

func _init() -> void:
	head_quality = randf_range(0.7, 1.0)
	tail_quality = randf_range(0.7, 1.0)

static func create_drop(head_pool: Array[WeaponPart], tail_pool: Array[WeaponPart], odds_head: Array[int], odds_tail: Array[int]) -> Weapon:
	# Validate
	assert(odds_head.size() == 5, "Enemy head drop odds array is not of length 5.")
	assert(odds_tail.size() == 5, "Enemy tail drop odds array is not of length 5.")
	
	var acc = 0
	for n in odds_head:
		acc += n
	if acc != 100:
		push_error("Enemy head drop odds do not add up to 100.")
		return
		
	acc = 0
	for n in odds_tail:
		acc += n
	if acc != 100:
		push_error("Enemy tail drop odds do not add up to 100.")
		return
	
	# Choose parts
	var luck_head := randi_range(1, 100)
	var luck_tail := randi_range(1, 100)
	var rarity_head = 0
	var rarity_tail = 0
	
	var r = 5		# current rarity
	var low_head = 100	# percentage lower bound of current rarity
	var low_tail = 100
	
	while r > 0:
		if rarity_head != 0 and rarity_tail != 0:
			break
			
		low_head -= odds_head[r - 1]
		low_tail -= odds_tail[r - 1]
		if luck_head > low_head and rarity_head == 0:
			rarity_head = r
		if luck_tail > low_tail and rarity_tail == 0:
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
	
		# Calculate final damage value
	weapon.damage = round(weapon.head.damage * weapon.head_quality) + round(weapon.tail.damage * weapon.tail_quality)
	
	return weapon

static func build_model(w: Weapon) -> Node3D:
	if w.head == null or w.tail == null:
		push_warning("Cannot build weapon with a null part.")
		return null
	
	var root := RigidBody3D.new()
	root.name = "weapon_inst_" + w.id 
	
	var head_node := w.head.model.instantiate() as Node3D
	var tail_node := w.tail.model.instantiate() as Node3D
	root.add_child(head_node)
	root.add_child(tail_node)
	
	var link_head := head_node.get_node_or_null("link_head") as Node3D
	var link_tail := tail_node.get_node_or_null("link_tail") as Node3D
	if link_head == null or link_tail == null:
		push_warning("Weapon built but one or more of its parts does not define a link point.")
		return root 
	
	tail_node.transform = head_node.transform * link_head.transform * link_tail.transform.affine_inverse()
	root = attach_drop_beam(w, root, link_head)
	
	# Bring parts' box colliders up to the root
	_hoist_shapes(root, head_node)
	_hoist_shapes(root, tail_node)
	return root

static func attach_drop_beam(w:Weapon, root: RigidBody3D, link: Node3D) -> RigidBody3D:
	var beam_node := BEAM.instantiate() as WeaponBeam
	root.add_child(beam_node)
	
	beam_node.position = link.position
	beam_node.set_color_by_rarity(w)
	return root

func get_color() -> Color:
	var r = max(head.rarity, tail.rarity)
	return rarity_to_color(r)

static func rarity_to_color(r: int) -> Color:
	var t := inverse_lerp(1.0, 5.0, r) # Normalized 1-5 range into 0-1
	var color := GRADIENT.sample(t)
	return color
	

# Helpers

static func _hoist_shapes(root: Node3D, part: Node) -> void:
	for shape in part.find_children("*", "CollisionShape3D", true, false):
		# accumulate the transform from the shape up to the root
		var xf := Transform3D.IDENTITY
		var n: Node = shape
		while n != root:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		shape.get_parent().remove_child(shape)
		root.add_child(shape)
		shape.transform = xf
