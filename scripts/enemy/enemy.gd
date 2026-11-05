class_name Enemy
extends CharacterBody3D

@export var data: EnemyData
var health: int

func _ready() -> void:
	health = data.max_health

# Health and Death

func take_damage(value: int) -> void:
	health -= value
	print(health)
	if health <= 0:
		die()

func die() -> void:
	drop_weapon()
	queue_free()

func drop_weapon() -> Weapon:
	var weapon = Weapon.create_drop(data.head_pool, data.tail_pool, data.odds_head, data.odds_tail)
	var model = Weapon.build_model(weapon)
	get_tree().current_scene.add_child(model)
	
	model.global_position = global_position
	model.rotation = Vector3(
		randf_range(0.0, TAU),
		randf_range(0.0, TAU),
		randf_range(0.0, TAU)
	)
	launch_random(model)
	
	return weapon

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
