class_name Player
extends Node3D

@export var max_health: int
var health: int

@export var inventory: PlayerInventory
var current_slot: int = 0
@export var player_weapon: Node3D
@export var player_camera: Camera3D

func _ready() -> void:
	health = max_health

# Weapons and Inventory
func pickup_weapon(w: Weapon, model: Node3D) -> void:
	if inventory.weapons[current_slot] != null:
		drop_weapon(current_slot)
	
	inventory.weapons[current_slot] = w
	inventory.models[w.id] = model
	switch_slot(current_slot)
	
func drop_weapon(slot: int) -> void:
	# Launch weapon model
	var model = Weapon.build_model(inventory.weapons[slot])
	get_tree().current_scene.add_child(model)
	
	model.collision_layer = 1 << (3 - 1)	# Prevent from colliding with player
	
	model.global_position = global_position
	model.rotation = Vector3(
		randf_range(0.0, TAU),
		randf_range(0.0, TAU),
		randf_range(0.0, TAU)
	)
	throw_weapon(model)
	
	# Clear inventory slot
	inventory.remove_weapon(inventory.weapons[slot])
	
func switch_slot(slot: int) -> void:
	current_slot = slot
	for child in player_weapon.get_children():
		player_weapon.remove_child(child)
	
	if inventory.weapons[current_slot] == null:
		return
	
	player_weapon.add_child(inventory.models[inventory.weapons[current_slot].id])

func get_current_weapon() -> Weapon:
	return inventory.weapons[current_slot]


# Input handling
func _unhandled_input(event: InputEvent) -> void:
	for action in InputMap.get_actions():
		# Switch slot
		if action.begins_with("slot_") and event.is_action_pressed(action):
			var slot = action.trim_prefix("slot_").to_int()
			switch_slot(slot)


# Helpers

func throw_weapon(body: RigidBody3D) -> void:
	var force := randf_range(7.0, 9.0)
	var dir := -player_camera.global_transform.basis.z
	body.apply_central_impulse(dir * force)
