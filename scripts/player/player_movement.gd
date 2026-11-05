extends CharacterBody3D

# ---- Sliding ----
@export var slide_speed: float = 12.0
@export var slide_friction: float = 10.0
# Temporary sideways speed in units/second; does not turn the base slide.
@export var slide_steer: float = 0.4

# ---- Movement ----
@export var SPEED: float = 8.0
@export var accelration: float = 60.0
@export var turn_accelration: float = 100.0
@export var friction: float = 60.0
@export var ground_snap_distance: float = 0.3

# ---- Jump / air ----
@export var JUMP_VELOCITY: float = 4.5
@export var WALL_JUMP_VELOCITY : float = JUMP_VELOCITY * 1.6
@export var Air_Control: float = 0.2
@export var fall_multiplier: float = 1.8
@export var air_drag: float = 0.4

# ---- Mouse look ----
@export var mouse_sens: float = 0.002
@export var max_pitch_degrees: float = 70.0

# ---- Wall Related -----
@export var wall_braking : float = 1.8 
@export var on_wall_friction : float = 1.8
@export var wall_fall_speed: float = 5.0
@export var stick_distance: float = 0.8


var stuck_on_wall : bool = false
var wall_set : bool = false
var saved_wall_normal: Vector3 = Vector3.ZERO

var is_sliding: bool = false
# Flat control velocity, separate from the engine's slope-adjusted velocity.
var _planar_velocity: Vector3 = Vector3.ZERO
# Base slide momentum. Steering is added separately, never stored into this.
var _slide_velocity: Vector3 = Vector3.ZERO

var wall_jump_count : int = 0

@onready var head: Node3D = $Head
var wall_ray: RayCast3D

func _ready() -> void:
	wall_ray = RayCast3D.new()
	wall_ray.debug_shape_custom_color = Color.BLUE
	wall_ray.debug_shape_thickness = 3.0
	add_child(wall_ray)
	wall_ray.enabled = true
	wall_ray.add_exception(self)

	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED # To identify walls, ceilings and floors.
	up_direction = Vector3.UP # Establish a baseline "up" direction.
	floor_constant_speed = true # Keep ground speed the same on slopes.
	floor_stop_on_slope = true # Stay still when standing on a slope.
	floor_snap_length = maxf(ground_snap_distance, 0.0) # Stay attached to nearby descending ground; jumping disables automatic snap.
	_planar_velocity = Vector3(velocity.x, 0.0, velocity.z) # Velocity of the XZ plane.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var grounded: bool = is_on_floor()
	if grounded:
		wall_jump_count = 0
		stuck_on_wall = false
		wall_set = false
	else:
		if(is_on_wall() and not wall_set): # inital grab
			point_at_wall(get_wall_normal())
			wall_set = true
	if(wall_set):
		stuck_on_wall = false
		if wall_ray.is_colliding():
			var normal = wall_ray.get_collision_normal()
			stuck_on_wall = absf(normal.dot(Vector3.UP)) < 0.2
		wall_set = stuck_on_wall
	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forwards", "move_backwards"
	)
	wall_jump_count = 0.0 if not (stuck_on_wall or wall_set) else wall_jump_count
	var direction: Vector3 = global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	direction.y = 0.0
	direction = direction.normalized()
	
	var jump_pressed := Input.is_action_just_pressed("ui_accept")
	var jumped := jump_pressed and grounded
	var wall_jumped := jump_pressed and stuck_on_wall
	var wants_slide: bool = grounded and not jumped and Input.is_action_pressed("crouch")



	if wants_slide and not is_sliding:
		var slide_dir: Vector3 = direction
		if slide_dir.is_zero_approx(): # If no movement inputs.
			# With no input, use existing movement; if stationary, use facing direction.
			if not _planar_velocity.is_zero_approx():
				slide_dir = _planar_velocity.normalized()
			else:
				slide_dir = -global_transform.basis.z
				slide_dir.y = 0.0
				slide_dir = slide_dir.normalized()
		# Direction times speed: start at slide_speed, or keep faster momentum.
		_slide_velocity = slide_dir * maxf(_planar_velocity.length(), slide_speed)
	is_sliding = wants_slide

	if is_sliding:
		# Keep the initial slide heading. Only excess base speed decays.
		var speed: float = _slide_velocity.length()
		if speed > slide_speed:
			speed = move_toward(speed, slide_speed, slide_friction * delta)
			_slide_velocity = _slide_velocity.normalized() * speed

		# A temporary view-relative offset, not acceleration or rotation.
		# Releasing A/D removes it; holding a key never accumulates a turn.
		var view_right: Vector3 = global_transform.basis.x
		view_right.y = 0.0
		view_right = view_right.normalized()
		_planar_velocity = _slide_velocity + view_right * input_dir.x * slide_steer
	else:
		if not direction.is_zero_approx():
			var rate: float = accelration
			# Negative dot: desired movement opposes current momentum.
			if _planar_velocity.dot(direction) < 0.0:
				rate = turn_accelration
			var top_speed: float = SPEED
			if not grounded:
				top_speed = maxf(SPEED, _planar_velocity.length())
				rate *= Air_Control
			# Approach the target velocity by acceleration times elapsed seconds.
			_planar_velocity = _planar_velocity.move_toward(
				direction * top_speed, rate * delta
			)
		elif grounded:
			# Approach the target velocity by acceleration times elapsed seconds.
			_planar_velocity = _planar_velocity.move_toward(Vector3.ZERO, friction * delta)

	if grounded:
		# Supply flat motion; move_and_slide handles the slope and floor snap.
		velocity.y = JUMP_VELOCITY if jumped else 0.0
	else:
		var gravity_mult: float = fall_multiplier if velocity.y < 0.0 else 1.0
		if(stuck_on_wall and velocity.y < 0.0):
			velocity.y = move_toward(velocity.y, -wall_fall_speed, wall_braking * gravity_mult * delta)
		else:
			velocity += get_gravity() * gravity_mult * delta
		var current_wall_friction : float = on_wall_friction if (stuck_on_wall) else 1.0
		# Gradually reduce horizontal speed in the air, consistently across frame rates.
		_planar_velocity *= exp(-air_drag * delta * current_wall_friction)
	
	if wall_jumped:
		var jump_strength = WALL_JUMP_VELOCITY / (2 ** wall_jump_count)
		_planar_velocity += saved_wall_normal.normalized() * jump_strength
		velocity.y = jump_strength
		stuck_on_wall = false
		wall_set = false
		wall_jump_count += 1 

	velocity.x = _planar_velocity.x
	velocity.z = _planar_velocity.z
	# Move using velocity; Godot may modify it in response to collisions.
	move_and_slide()

	# Godot identifies walls for us. Remove only motion pushing into the wall.
	if is_on_wall():
		var wall_normal: Vector3 = get_wall_normal()
		wall_normal.y = 0.0
		wall_normal = wall_normal.normalized()
		if _planar_velocity.dot(wall_normal) < 0.0:
			_planar_velocity = _planar_velocity.slide(wall_normal)
		if is_sliding and _slide_velocity.dot(wall_normal) < 0.0:
			_slide_velocity = _slide_velocity.slide(wall_normal)

	if not is_on_floor():
		# Preserve the engine's outgoing horizontal motion when leaving ground.
		_planar_velocity = Vector3(velocity.x, 0.0, velocity.z)
		is_sliding = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		head.rotate_x(-event.relative.y * mouse_sens)
		head.rotation.x = clampf(
			head.rotation.x,
			deg_to_rad(-max_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func point_at_wall(normal :Vector3):
	saved_wall_normal = normal
	var endpoint = wall_ray.global_position - saved_wall_normal * stick_distance
	wall_ray.target_position = wall_ray.to_local(endpoint)
	wall_ray.force_raycast_update()
