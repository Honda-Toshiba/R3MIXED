class_name ShootingEnemy
extends Enemy

@export var walk_speed: float = 3.0
@export var stop_distance: float = 1.8
@export var repath_distance: float = 0.5

const WALK_ANIMATION: StringName = &"CharacterArmature|Walk"
const IDLE_ANIMATION: StringName = &"CharacterArmature|Idle"

@onready var animator: AnimationPlayer = $"Root Scene/AnimationPlayer"

var player_body: CharacterBody3D


func _ready() -> void:
	super._ready()

	player_body = get_tree().get_first_node_in_group("player") as CharacterBody3D

	if player_body == null:
		push_error("WalkingEnemy: Player not found!")
		set_physics_process(false)
		return

	if animator == null:
		push_error("WalkingEnemy: AnimationPlayer not found!")
		set_physics_process(false)
		return

	set_physics_process(false)
	await get_tree().physics_frame

	set_physics_process(true)


func _physics_process(delta: float) -> void:
	var to_player: Vector3 = player_body.global_position - global_position
	to_player.y = 0.0

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	move_and_slide()

func play_animation(animation_name: StringName) -> void:
	if animator.current_animation != animation_name or not animator.is_playing():
		animator.play(animation_name)
