class_name PlayerInventory
extends Node

@export var max_capacity: int
var weapons: Array[Weapon] 
var models: Dictionary[StringName, Node3D] = {}

func _ready() -> void:
	# Initialization
	weapons = []
	weapons.resize(max_capacity)

func add_weapon(w: Weapon, model: Node3D) -> Weapon:
	if weapons.size() >= max_capacity:
		return null
	
	weapons.append(w)
	models[w.id] = model
	return w

func remove_weapon(w: Weapon) -> void:
	weapons[weapons.find(w)] = null
	models.erase(w.id)
	return
