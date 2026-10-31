class_name Enemy
extends CharacterBody3D

@export var data: EnemyData
var health: int

func _ready() -> void:
	health = data.max_health

func die() -> void:
	var weapon_drop = Weapon.create_drop(data.head_pool, data.tail_pool, data.odds)
	var weapon_node = Weapon.build_model(weapon_drop)
	
	get_tree().current_scene.add_child(weapon_node)
	weapon_node.global_position = global_position

# For testing
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			die()
