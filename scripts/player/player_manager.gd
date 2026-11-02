class_name Player
extends Node

@export var inventory: PlayerInventory
var current_slot: int = 0
@export var player_weapon: Node3D

# Input handling
func _unhandled_input(event: InputEvent) -> void:
	for action in InputMap.get_actions():
		# Switch slot
		if action.begins_with("slot_") and event.is_action_pressed(action):
			var slot = action.trim_prefix("slot_").to_int() - 1
			switch_slot(slot)
	
# Weapons and Inventory
func pickup_weapon(w: Weapon, model: Node3D) -> void:
	if inventory.weapons[current_slot] != null:
		print() # throw held weapon
	
	inventory.weapons[current_slot] = w
	inventory.models[w.id] = model
	switch_slot(current_slot)
	
func switch_slot(slot: int) -> void:
	current_slot = slot
	for child in player_weapon.get_children():
		player_weapon.remove_child(child)
	
	if inventory.weapons[current_slot] == null:
		return
	
	player_weapon.add_child(inventory.models[inventory.weapons[current_slot].id])
