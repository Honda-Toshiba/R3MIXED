extends Node

@export var camera: Camera3D
@export var ray_length := 3.0

const ITEM_CARD = preload("res://scenes/prefabs/item_card.tscn")
var item_card: ItemCard

func _ready() -> void:
	item_card = ITEM_CARD.instantiate() as ItemCard
	get_tree().current_scene.add_child.call_deferred(item_card)

func _physics_process(_delta: float) -> void:
	var hit := look_raycast()
	if hit:
		print("Hit at: ", hit.position)
		item_card.position = hit.position
		item_card.display_weapon((hit.collider.get_parent() as WeaponBeam).weapon)
		item_card.show()
	if not hit:
		item_card.hide()

func look_raycast() -> Dictionary:
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z) * ray_length

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 1 << 3         # only layer 4

	var space := camera.get_world_3d().direct_space_state
	return space.intersect_ray(query)
