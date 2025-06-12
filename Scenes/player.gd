extends CharacterBody3D

@export var sens := 0.1
@export var blend_speed: float = 5.0
@export var gravity: float = -650.0
@export var rotation_speed: float = 4.0
@export var run_speed: float = 475.0
@export var walk_speed: float = 225.0
@export var jump_velocity: float = 310.0

@export var normal_fov: float = 70.0
@export var sprint_fov: float = 90.0
@export var fov_blend_speed: float = 5.0

var is_sprinting: bool = false

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var pivot = $CamRoot
@onready var camera: Camera3D = $CamRoot/SpringArm3D/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	animation_tree.active = true

func _physics_process(delta: float) -> void:
	var move_input = Vector3.ZERO

	# Movement input
	if Input.is_action_pressed("forward"):
		move_input.z += 1  # Forward: negative Z
	if Input.is_action_pressed("backward"):
		move_input.z -= 1  # Backward: positive Z
	if Input.is_action_pressed("left"):
		move_input.x += 1  # Left: negative X
	if Input.is_action_pressed("right"):
		move_input.x -= 1  # Right: positive X

	is_sprinting = Input.is_action_pressed("sprint") and is_on_floor()

	move_input = move_input.normalized()
	var direction = (transform.basis * move_input).normalized()

	var current_speed = run_speed if is_sprinting else walk_speed
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Apply gravity
	velocity.y += gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	# ---- Animation Logic ----
	var is_moving = move_input.length_squared() > 0.01
	var on_floor = is_on_floor()
	var is_falling = not on_floor and velocity.y < 0
	var just_landed = on_floor and velocity.y == 0 and not is_moving
	var is_not_falling = just_landed and velocity.y == 0
	var jumping = velocity.y == 1
	
	
	animation_tree.set("parameters/conditions/Idle", not is_moving and on_floor)
	animation_tree.set("parameters/conditions/Walk", is_moving and not is_sprinting and on_floor)
	animation_tree.set("parameters/conditions/Run", is_moving and is_sprinting and on_floor)
	animation_tree.set("parameters/conditions/Falling", is_falling)
	animation_tree.set("parameters/conditions/Landed", just_landed and is_not_falling)
	animation_tree.set("parameters/conditions/Jumping", jumping)
	
	
	
	
	blend_fov(delta)

func blend_fov(delta: float) -> void:
	var target_fov = sprint_fov if is_sprinting else normal_fov
	camera.fov = lerp(camera.fov, target_fov, fov_blend_speed * delta)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens))
		pivot.rotate_x(deg_to_rad(event.relative.y * sens))
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(45))
