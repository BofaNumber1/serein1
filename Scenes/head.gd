extends Node3D

@onready var chb3d = $".."
@onready var hd = $"."
@export var sensitivity: float = 0.3
var v = Vector3()


# Called when the node enters the scene tree for the first time
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Called every frame. 'delta' is the elapsed time since previous frame.
func _process(delta: float) -> void:
	hd.rotation_degrees.x = v.x
	chb3d.rotation_degrees.y = v.y
	
	
func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		v.y -= (event.relative.x * sensitivity)
		v.z -= (event.relative.y * sensitivity)
		v.x = clamp(v.x, -40, 40)
		chb3d.rotation_degrees.x -= event.relative.y * sensitivity
		chb3d.rotation_degrees.x = clamp(chb3d.rotation_degrees.x, -40, 40)  # Limit up/down
		chb3d.rotation_degrees.y -= event.relative.x * sensitivity  # Already handles left/right
