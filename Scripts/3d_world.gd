extends Node3D

@onready var pause_screen_scene = preload("res://Scenes/pause_screen.tscn")
var pause_screen_instance: Control

func _ready():
	pause_screen_instance = pause_screen_scene.instantiate()
	pause_screen_instance.visible = false
	add_child(pause_screen_instance)
	pause_screen_instance.connect("resume_pressed", Callable(self, "resume_game"))

func _input(event):
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

func pause_game():
	get_tree().paused = true
	pause_screen_instance.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func resume_game():
	get_tree().paused = false
	pause_screen_instance.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
