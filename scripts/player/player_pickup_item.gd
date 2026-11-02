extends Node

@export var player: Player
@export var camera: Camera3D
@export var ray_length := 3.0

const ITEM_CARD = preload("res://scenes/prefabs/item_card.tscn")
var item_card: ItemCard

var target_node: Node
var target_weapon: Weapon

func _ready() -> void:
	item_card = ITEM_CARD.instantiate() as ItemCard
	get_tree().current_scene.add_child.call_deferred(item_card)

# Display item card if looking at weaopn
func _physics_process(_delta: float) -> void:
	var hit := look_raycast()
	if hit:
		# Display item card
		target_node = hit.collider.get_parent() # Reference to weapon_beam node
		target_weapon = (target_node as WeaponBeam).weapon
		item_card.position = hit.collider.get_parent().position
		item_card.position.y = hit.position.y + 0.4		# Offset card upwards a bit
		item_card.display_weapon(target_weapon)
		item_card.show()
	if not hit:
		item_card.hide()
		target_node = null
		target_weapon = null

# Cast ray to detect if looking at beam
func look_raycast() -> Dictionary:
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z) * ray_length

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 1 << 3         # only layer 4

	var space := camera.get_world_3d().direct_space_state
	return space.intersect_ray(query)

# Pick up weapon if interact
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and target_weapon != null:
		player.pickup_weapon(target_weapon, Weapon.build_viewmodel(target_weapon))
		target_node.get_parent().queue_free() # Delete weapon drop
