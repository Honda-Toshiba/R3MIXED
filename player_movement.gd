extends CharacterBody3D

# ---- Movement (all floats) ----
@export var SPEED: float = 5.0
@export var SHIFT: float = 5.0               # sprint speed = SPEED + SHIFT
@export var accelration: float = 60.0        # speed gained per second
@export var turn_accelration: float = 100.0  # used when input opposes your velocity
@export var slowdown: float = 60.0           # speed lost per second with no input

# ---- Jump / air (floats) ----
@export var JUMP_VELOCITY: float = 4.5
@export var Air_Control: float = 0.6

# ---- Mouse look (floats) ----
@export var mouse_sens: float = 0.002
@export var max_pitch_degrees: float = 70.0

var sprint_bonus: float = 0.0

@onready var head: Node3D = $Head

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var air_control: float = 1.0

	if not is_on_floor():
		velocity += get_gravity() * delta
		air_control = Air_Control
	else:
		sprint_bonus = SHIFT if Input.is_action_pressed("sprint") else 0.0

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)

	if direction != Vector3.ZERO:
		var rate: float = accelration
		if horizontal.dot(direction) < 0.0:
			rate = turn_accelration
		var target: Vector3 = direction * (SPEED + sprint_bonus)
		var step: float = rate * air_control * delta
		horizontal = horizontal.move_toward(target, step)
	else:
		var step: float = slowdown * air_control * delta
		horizontal = horizontal.move_toward(Vector3.ZERO, step)

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
