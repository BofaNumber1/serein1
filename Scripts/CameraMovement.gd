extends Node3D

var mouse_cam_sensitivity = 0.005
var twist_input = 0.0
var pitch_input = 0.0
var input_dir

@onready var twist_pivot = $h
@onready var pitch_pivot = $h/v

func _physics_process(delta):
	# mouse camera control
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	
	# limit camera rotation
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x,
		deg_to_rad(-90),
		deg_to_rad(45)
	)
	
	# reset twist and pivot inputs back to zero
	twist_input = 0.0
	pitch_input = 0.0
	
func _unhandled_input(event):
	# inputs for mouse
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * mouse_cam_sensitivity
			pitch_input = -event.relative.y * mouse_cam_sensitivity
