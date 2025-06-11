extends CharacterBody3D

@export var sens := 0.1
var twist_input := 0.0
var pitch_input := 0.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var pivot = $CamRoot
@onready var camera: Camera3D = $CamRoot/SpringArm3D/Camera3D

@export var blend_speed: float = 5.0
@export var gravity: float = -650.0
@export var rotation_speed: float = 4.0
@export var run_speed: float = 475.0
@export var walk_speed: float = 225.0
@export var jump_velocity: float = 300.0

@export var normal_fov: float = 70.0
@export var sprint_fov: float = 90.0
@export var fov_blend_speed: float = 5.0

var current_idle_blend: float = 0.0
var airborne_blend: float = 0.0
var is_sprinting: bool = false


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	var move_direction = Vector3.ZERO
	
	is_sprinting = Input.is_action_pressed("sprint") and is_on_floor()
	
	# Movement inputs
	if Input.is_action_pressed("backward"):
		move_direction -= transform.basis.z
	if Input.is_action_pressed("forward"):
		move_direction += transform.basis.z
	if Input.is_action_pressed("left"):
		move_direction += transform.basis.x  # ✅ Move left
	if Input.is_action_pressed("right"):
		move_direction -= transform.basis.x  # ✅ Move right
	
	var current_speed = run_speed if is_sprinting else walk_speed
	if move_direction != Vector3.ZERO:
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed
	else:
		velocity.x = 0
		velocity.z = 0
	
	# Gravity and jumping
	velocity.y += gravity * delta
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	move_and_slide()
	
	blend_idle_walk(delta)
	blend_air_land(delta)
	blend_fall_jump(delta)
	blend_fov(delta)


func blend_idle_walk(delta: float) -> void:
	var max_speed = run_speed if is_sprinting else walk_speed
	var target_speed = clamp(velocity.length() / max_speed, 0.0, 1.0)
	current_idle_blend = lerp(current_idle_blend, target_speed, blend_speed * delta)
	animation_tree.set("parameters/BlendIdleWalk/blend_amount", current_idle_blend)


func blend_air_land(delta: float) -> void:
	var target_airborne_blend = 1.0 if not is_on_floor() else 0.0
	airborne_blend = lerp(airborne_blend, target_airborne_blend, blend_speed * delta)
	animation_tree.set("parameters/BlendAirLand/blend_amount", airborne_blend)


func blend_fall_jump(delta: float) -> void:
	var vertical_speed = clamp(velocity.y / jump_velocity, -1.0, 1.0)
	animation_tree.set("parameters/BlendFallJump/blend_position", vertical_speed)


func blend_fov(delta: float) -> void:
	var target_fov = sprint_fov if is_sprinting else normal_fov
	camera.fov = lerp(camera.fov, target_fov, fov_blend_speed * delta)


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens))
		pivot.rotate_x(deg_to_rad(event.relative.y * sens))
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(45))
