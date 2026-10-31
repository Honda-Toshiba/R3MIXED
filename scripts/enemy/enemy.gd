class_name Enemy
extends CharacterBody3D

@export var data: EnemyData
var health: int

func _ready() -> void:
	health = data.max_health

func die() -> void:
	var drop_weapon = Weapon.create_drop(data.head_pool, data.tail_pool, data.odds)
	var drop_model = Weapon.build_model(drop_weapon)
	
	get_tree().current_scene.add_child(drop_model)
	drop_model.global_position = global_position
	drop_model.rotation = Vector3(
		randf_range(0.0, TAU),
		randf_range(0.0, TAU),
		randf_range(0.0, TAU)
	)
	launch_random(drop_model)

# For testing
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			die()

# Helpers

const LAUNCH_FORCE := 8.0

func launch_random(body: RigidBody3D) -> void:
	var dir := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(0.3, 1.0),    # bias upward so it pops out of the ground
		randf_range(-1.0, 1.0)
	).normalized()
	body.apply_central_impulse(dir * LAUNCH_FORCE)
