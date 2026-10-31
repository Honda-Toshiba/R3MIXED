extends CharacterBody3D

# ---- Sliding ----
@export var slide_speed: float = 12.0       # constant speed while sliding
@export var slide_friction: float = 10.0    # only bleeds speed ABOVE slide_speed
@export var slide_steer: float = 8.0        # how much you can curve mid-slide

# ---- Movement ----
@export var SPEED: float = 8.0
@export var accelration: float = 60.0
@export var turn_accelration: float = 100.0
@export var friction: float = 60.0

# ---- Jump / air ----
@export var JUMP_VELOCITY: float = 4.5
@export var Air_Control: float = 0.6
@export var fall_multiplier: float = 1.8

# ---- Mouse look ----
@export var mouse_sens: float = 0.002
@export var max_pitch_degrees: float = 70.0

var is_sliding: bool = false

@onready var head: Node3D = $Head

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var air_control: float = 1.0
	var gravity_mult: float = 1.0
	var jumped_this_frame: bool = false

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)

	if not is_on_floor():
		if velocity.y < 0.0:
			gravity_mult = fall_multiplier
		velocity += get_gravity() * gravity_mult * delta
		air_control = Air_Control
		is_sliding = false

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumped_this_frame = true
		is_sliding = false

	# Slide is HELD: starts when crouch is down on the floor, ends when released
	if is_on_floor() and not jumped_this_frame and Input.is_action_pressed("crouch"):
		if not is_sliding:
			is_sliding = true
			# Slide direction: input, else current motion, else where you're facing
			var slide_dir: Vector3 = -transform.basis.z
			if direction != Vector3.ZERO:
				slide_dir = direction
			elif horizontal.length() > 0.1:
				slide_dir = horizontal.normalized()
			# Never slower than slide_speed, but keep any extra speed you came in with
			horizontal = slide_dir * max(horizontal.length(), slide_speed)
	else:
		is_sliding = false

	if is_sliding:
		var speed: float = horizontal.length()
		# Steering: curve the direction without changing the speed
		var side: Vector3 = transform.basis.x * input_dir.x * slide_steer
		horizontal = (horizontal + side * delta).normalized() * speed
		# Too fast? Bleed down to slide_speed, never below it
		if speed > slide_speed:
			horizontal = horizontal.move_toward(horizontal.normalized() * slide_speed, slide_friction * delta)
	else:
		if direction != Vector3.ZERO:
			var rate: float = accelration
			if horizontal.dot(direction) < 0.0:
				rate = turn_accelration
			var top_speed: float = SPEED
			if not is_on_floor():
				top_speed = max(SPEED, horizontal.length())   # air: steer, don't brake
			var target: Vector3 = direction * top_speed
			horizontal = horizontal.move_toward(target, rate * air_control * delta)
		elif is_on_floor():
			horizontal = horizontal.move_toward(Vector3.ZERO, friction * delta)

	if is_on_floor() and not jumped_this_frame:
		velocity = horizontal.slide(get_floor_normal())
	else:
		velocity.x = horizontal.x
		velocity.z = horizontal.z

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		head.rotate_x(-event.relative.y * mouse_sens)
		head.rotation.x = clamp(
			head.rotation.x,
			deg_to_rad(-max_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
