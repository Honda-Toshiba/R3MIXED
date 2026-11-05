extends Node

@export var player: Player
@export var hitbox: Area3D
@export var camera: Camera3D
@export var enemy_card: EnemyCard
@onready var enemy_card_timer: Timer = $enemy_card_timer

func _ready() -> void:
	enemy_card_timer.timeout.connect(_on_timer_timeout)


# Main combat functionality

func attack() -> void:
	for enemy in hitbox.get_overlapping_bodies():
		damage_enemy(enemy, player.get_current_weapon().damage)

func damage_enemy(enemy: Enemy, value: int) -> void:
	enemy.take_damage(value)
	

# HUD Elements

	# Cast ray to detect if looking at enemy
func _physics_process(_delta: float) -> void:
	var hit := look_raycast()
	if hit:
		var enemy = hit.collider as Enemy
		enemy_card.show_card(enemy)
		enemy_card_timer.start()

const ray_length: float = 40.0

func look_raycast() -> Dictionary:
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z) * ray_length

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 1 << (5 - 1)         # only layer 5

	var space := camera.get_world_3d().direct_space_state
	return space.intersect_ray(query)

func _on_timer_timeout() -> void:
	enemy_card.hide_card()


# Input handling

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()
