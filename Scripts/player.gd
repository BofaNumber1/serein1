extends CharacterBody3D

var speed = 5.0
var sprint_speed = 10.0
var turn_speed = 30
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var jump_impulse = 10.0

@onready var cam_h = $CamRoot/h
@onready var cam_v = $CamRoot/h/v
@onready var anim = $PlayerBody/AnimationPlayer

var parent

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	parent = get_parent()

func _unhandled_input(event):
	if Input.is_action_just_pressed("pause"):
		get_tree().change_scene_to_file("res://Scenes/pause_screen.tscn")

func _process(delta):
	parent.position = position

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	print("Input dir: ", input_dir)

# Get the camera's forward and right directions
	var cam_forward = cam_h.transform.basis.z
	var cam_right = cam_h.transform.basis.x

# Flatten the directions to avoid vertical movement
	cam_forward.y = 0
	cam_right.y = 0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

# Combine inputs with camera directions
	var direction = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()



	var is_sprinting = Input.is_action_pressed("sprint")
	var current_speed = sprint_speed if is_sprinting else speed


	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	# Movement
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		# Rotate to face movement direction
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)

		# Play animations
		if is_on_floor():
			if is_sprinting:
				anim.play("Running")
			else:
				anim.play("Walking")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

		# Play idle animation
		if is_on_floor():
			anim.play("OffensiveIdle")

	# Jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_impulse
		anim.play("Jumping")

	# Falling animation
	if not is_on_floor():
		anim.play("FallingIdle")

	move_and_slide()
