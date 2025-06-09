extends CharacterBody3D

@onready var animation_tree: AnimationTree = $AnimationTree

@export var blend_speed: float = 5.0
@export var gravity: float = -40.0
@export var rotation_speed: float = 4.0
@export var run_speed: float = 475.0
@export var walk_speed: float = 225.0
@export var jump_velocity: float = 25.0

var current_idle_blend: float = 0.0
var airborne_blend: float = 0.0
var is_sprinting: bool = false  # New variable to track sprint state

func _physics_process(delta: float) -> void:
	var move_direction = Vector3.ZERO
	
	# Check for sprint input (e.g., Shift key)
	is_sprinting = Input.is_action_pressed("sprint") and is_on_floor()  # Sprint only when on ground
	
	if Input.is_action_pressed("left"):
		rotate_y(rotation_speed * delta)
	if Input.is_action_pressed("right"):
		rotate_y(-rotation_speed * delta)
	
	if Input.is_action_pressed("forward"):
		move_direction = transform.basis.z
	
	# Use run_speed if sprinting, otherwise use walk_speed
	var current_speed = run_speed if is_sprinting else walk_speed
	if move_direction != Vector3.ZERO:
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed
	else:
		velocity.x = 0
		velocity.z = 0
	
	velocity.y += gravity * delta
	
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	move_and_slide()
	
	blend_idle_walk(delta)
	blend_air_land(delta)
	blend_fall_jump(delta)

func blend_idle_walk(delta: float) -> void:
	# Adjust target_speed to account for run_speed when sprinting
	var max_speed = run_speed if is_sprinting else walk_speed
	var target_speed = clamp(velocity.length() / max_speed, 0.0, 1.0)
	current_idle_blend = lerp(
		current_idle_blend,
		target_speed,
		blend_speed * delta)
	animation_tree.set(
		"parameters/BlendIdleWalk/blend_amount", 
		current_idle_blend
	)

func blend_air_land(delta: float) -> void:
	var target_airborne_blend = 1.0 if not is_on_floor() else 0.0
	airborne_blend = lerp(
		airborne_blend,
		target_airborne_blend,
		blend_speed * delta
	)
	animation_tree.set("parameters/BlendAirLand/blend_amount", airborne_blend)

func blend_fall_jump(delta: float) -> void:
	var vertical_speed = clamp(
		velocity.y / jump_velocity,
		-1.0,
		1.0)
	animation_tree.set(
		"parameters/BlendFallJump/blend_position", vertical_speed
	)
