class_name WalkingEnemy
extends Enemy

@export var walk_speed: float = 3.0
@export var stop_distance: float = 1.8
@export var repath_distance: float = 0.5

const WALK_ANIMATION: StringName = &"CharacterArmature|Walk"
const IDLE_ANIMATION: StringName = &"CharacterArmature|Idle"

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
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

	nav_agent.target_position = player_body.global_position
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	var to_player: Vector3 = player_body.global_position - global_position
	to_player.y = 0.0

	if to_player.length() <= stop_distance:
		stop_walking()
	else:
		chase_player()

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func chase_player() -> void:
	if nav_agent.target_position.distance_to(player_body.global_position) > repath_distance:
		nav_agent.target_position = player_body.global_position

	if nav_agent.is_navigation_finished():
		stop_walking()
		return

	var next_point: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = next_point - global_position
	direction.y = 0.0

	if direction.length() < 0.05:
		stop_walking()
		return

	direction = direction.normalized()

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	look_at(global_position + direction, Vector3.UP)
	play_animation(WALK_ANIMATION)


func stop_walking() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	play_animation(IDLE_ANIMATION)


func play_animation(animation_name: StringName) -> void:
	if animator.current_animation != animation_name or not animator.is_playing():
		animator.play(animation_name)
