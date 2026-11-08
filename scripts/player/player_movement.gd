extends CharacterBody3D

# ---- Sliding ----
@export var slide_speed: float = 12.0
@export var slide_friction: float = 10.0
# Temporary sideways speed in units/second; does not turn the base slide.
@export var slide_steer: float = 0.4
signal slide_start()
signal slide_end()

# ---- Movement ----
@export var SPEED: float = 8.0
@export var accelration: float = 60.0
@export var turn_accelration: float = 100.0
@export var friction: float = 60.0
@export var ground_snap_distance: float = 0.3
signal walking()

# ---- Jump / air ----
@export var JUMP_VELOCITY: float = 4.5
@export var WALL_JUMP_VELOCITY : float = JUMP_VELOCITY * 1.6
@export var Air_Control: float = 0.2
@export var fall_multiplier: float = 1.8
@export var air_drag: float = 0.4

signal in_the_air
signal stop_in_the_air
signal in_the_air_high_speed()

# ---- Mouse look ----
@export var mouse_sens: float = 0.002
@export var max_pitch_degrees: float = 70.0

# ---- Wall Related -----
@export var wall_braking : float = 1.8 
@export var on_wall_friction : float = 1.8
@export var wall_fall_speed: float = 5.0
@export var stick_distance: float = 0.8
@export var wall_jump_limit : int = 4

signal wall_bounce()

@export var dash_distance: float = 3.0
@export var dash_duration: float = 0.09
@onready var dash_cooldown: Timer = $dash_cooldown

signal dash_recharged
signal dash_used_up
#------
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var capsule: CapsuleShape3D = collider.shape as CapsuleShape3D
@onready var head: Node3D = $Head
#------
@onready var standing_height := capsule.height # 2.06121826171875
@onready var standing_center_y := collider.position.y
@onready var standing_camera_height = head.position
#----------
@export var slide_height: float = 1.2
#----------
var dash_stop_pending: bool = false
var dash_direction: Vector3 = Vector3.ZERO
var dash_time_left: float = 0.0
var dash_charges: int = 3
#----------
var stuck_on_wall : bool = false
var wall_set : bool = false
var saved_wall_normal: Vector3 = Vector3.ZERO
var wall_jump_count : int = 0
var wall_ray: RayCast3D
#----------
var is_sliding: bool = false
var _slide_velocity: Vector3 = Vector3.ZERO
#----------
var _planar_velocity: Vector3 = Vector3.ZERO
#----------
var buffered_jump_duration :float = 0.1
var current_buffered_jump_left : float = 0.0
#----------
var cayote_time : float = 0.8
var cayote_time_left: float = 0.0



func _ready() -> void:
	wall_ray = RayCast3D.new()
	wall_ray.debug_shape_custom_color = Color.BLUE
	wall_ray.debug_shape_thickness = 3.0
	add_child(wall_ray)
	wall_ray.enabled = true
	wall_ray.add_exception(self)
	print(standing_height)

	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED # To identify walls, ceilings and floors.
	up_direction = Vector3.UP # Establish a baseline "up" direction.
	floor_constant_speed = true # Keep ground speed the same on slopes.
	floor_stop_on_slope = true # Stay still when standing on a slope.
	floor_snap_length = maxf(ground_snap_distance, 0.0) # Stay attached to nearby descending ground; jumping disables automatic snap.
	_planar_velocity = Vector3(velocity.x, 0.0, velocity.z) # Velocity of the XZ plane.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var grounded := is_on_floor()
	if wall_set:
		_check_wall_contact()
	if grounded:
		stop_in_the_air.emit()
		_reset_wall_state_on_ground()
		cayote_time_left = cayote_time
	else:
		in_the_air.emit()
		cayote_time_left = maxf(cayote_time_left - delta, 0.0)
		_try_grab_wall()

	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forwards", "move_backwards"
	)
	var direction: Vector3 = global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	direction.y = 0.0
	direction = direction.normalized()

	var jump_pressed := Input.is_action_just_pressed("ui_accept")
	
	if jump_pressed:
		current_buffered_jump_left = buffered_jump_duration
	else:
		current_buffered_jump_left = maxf(current_buffered_jump_left - delta, 0.0)

	var jump_requested := current_buffered_jump_left > 0.0
	var jumped := jump_requested and (grounded or cayote_time_left > 0.0)
	var wall_jumped := jump_requested and stuck_on_wall

	var wants_slide: bool = grounded and not jumped and Input.is_action_pressed("crouch")
	# About to leave a slide: stay low if the standing capsule wouldn't fit.
	if is_sliding and grounded and not wants_slide:
		var height_to_gain := standing_height - capsule.height
		if test_move(global_transform, Vector3.UP * height_to_gain):
			wants_slide = true
			jumped = false

	if Input.is_action_just_pressed("dash") and dash_time_left <= 0.0 and not dash_stop_pending and dash_cooldown.is_stopped() and dash_charges > 0:
		dash_start()

	if wants_slide and not is_sliding:
		_start_slide(direction)

	elif not wants_slide and is_sliding:
		_end_slide()

	is_sliding = wants_slide
	crouch_pov(is_sliding)

	if is_sliding:
		_update_slide(input_dir.x, delta)
	else:
		_update_walk(direction, grounded, delta)

	if jumped:
		velocity.y = JUMP_VELOCITY
		current_buffered_jump_left = 0.0
		cayote_time_left = 0.0
	elif grounded:
		velocity.y = 0.0
	else:
		_apply_air_motion(delta)

	var can_wall_jump = wall_jump_count < wall_jump_limit and dash_time_left <= 0.0
	if wall_jumped and can_wall_jump and not jumped:
		_apply_wall_jump()
		current_buffered_jump_left = 0.0
		cayote_time_left = 0.0

	if dash_time_left > 0.0:
		_apply_dash(delta)

	elif dash_stop_pending:
		dash_stop_pending = false
		
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
	if not is_on_floor():
		# Preserve the engine's outgoing horizontal motion when leaving ground.
		_planar_velocity = Vector3(velocity.x, 0.0, velocity.z)
		if(is_sliding):
			_end_slide()

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

func crouch_pov(sliding: bool) -> void:
	capsule.height = slide_height if sliding else standing_height
	var height_lost: float = standing_height - capsule.height

	# Lower the capsule's center by half the change to keep the feet planted.
	collider.position.y = standing_center_y - height_lost * 0.5

	# Lower the eyes with the top of the capsule.
	head.position.y = standing_camera_height.y - height_lost

func _start_slide(direction : Vector3):
	var slide_dir: Vector3 = direction
	if slide_dir.is_zero_approx():
		# No input: use current movement, or face forward if standing still.
		if not _planar_velocity.is_zero_approx():
			slide_dir = _planar_velocity.normalized()
		else:
			slide_dir = -global_transform.basis.z
			slide_dir.y = 0.0
			slide_dir = slide_dir.normalized()

	# Set the slide velocity once, when the slide starts.
	_slide_velocity = slide_dir * maxf(_planar_velocity.length(), slide_speed)
	slide_start.emit()

func _update_slide(side_input, delta):
	var speed: float = _slide_velocity.length()
	if speed > slide_speed:
		speed = move_toward(speed, slide_speed, slide_friction * delta)
		_slide_velocity = _slide_velocity.normalized() * speed

	# A temporary view-relative offset, not acceleration or rotation.
	# Releasing A/D removes it; holding a key never accumulates a turn.
	var view_right: Vector3 = global_transform.basis.x
	view_right.y = 0.0
	view_right = view_right.normalized()
	_planar_velocity = _slide_velocity + view_right * side_input * slide_steer

func _end_slide() -> void:
	if is_sliding:
		is_sliding = false
		slide_end.emit()

func _update_walk(move_direction ,grounded ,delta):
	if not move_direction.is_zero_approx():
		var rate: float = accelration
		# Negative dot: desired movement opposes current momentum.
		if _planar_velocity.dot(move_direction) < 0.0:
			rate = turn_accelration
		var top_speed: float = SPEED
		if not grounded:
			top_speed = maxf(SPEED, _planar_velocity.length())
			rate *= Air_Control
		# Approach the target velocity by acceleration times elapsed seconds.
		_planar_velocity = _planar_velocity.move_toward(
			move_direction * top_speed, rate * delta
		)
	elif grounded:
		# Approach the target velocity by acceleration times elapsed seconds.
		_planar_velocity = _planar_velocity.move_toward(Vector3.ZERO, friction * delta)

func _reset_wall_state_on_ground() -> void:
	wall_jump_count = 0
	stuck_on_wall = false
	wall_set = false

func _try_grab_wall() -> void:
	if is_on_wall() and not wall_set:
		point_at_wall(get_wall_normal())
		wall_set = true

func _check_wall_contact() -> void:
	stuck_on_wall = false
	if wall_ray.is_colliding():
		var normal := wall_ray.get_collision_normal()
		stuck_on_wall = absf(normal.dot(Vector3.UP)) < 0.2

	wall_set = stuck_on_wall

func _apply_air_motion(delta):
	var gravity_mult: float = fall_multiplier if velocity.y < 0.0 else 1.0
	if(stuck_on_wall and velocity.y < 0.0):
		velocity.y = move_toward(velocity.y, -wall_fall_speed, wall_braking * gravity_mult * delta)
	else:
		velocity += get_gravity() * gravity_mult * delta
	var current_wall_friction : float = on_wall_friction if (stuck_on_wall) else 1.0
	# Gradually reduce horizontal speed in the air, consistently across frame rates.
	_planar_velocity *= exp(-air_drag * delta * current_wall_friction)

func _apply_wall_jump():
	var jump_strength = WALL_JUMP_VELOCITY / (2 ** wall_jump_count)
	_planar_velocity += saved_wall_normal.normalized() * jump_strength
	velocity.y = jump_strength
	stuck_on_wall = false
	wall_set = false
	wall_jump_count += 1 

func _apply_dash(delta):
	var dash_speed := dash_distance / dash_duration
	var step_time := minf(delta, dash_time_left)
	var dash_velocity :Vector3 = dash_direction * dash_speed * (step_time / delta)
	_planar_velocity = Vector3(dash_velocity.x, 0.0, dash_velocity.z)
	velocity.y = dash_velocity.y
	dash_time_left -= step_time
	dash_stop_pending = dash_time_left <= 0.0

func dash_start():
	dash_direction = (-head.global_transform.basis.z).normalized()
	dash_time_left = dash_duration
	dash_charges -= 1
	dash_used_up.emit() #updates ui perhaps
	dash_cooldown.start()

func _on_dash_cooldown_timeout() -> void:
	dash_charges += min(dash_charges + 1, 3)
	dash_recharged.emit()
