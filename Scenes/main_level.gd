extends Node3D

var paused = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://Scenes/pause_screen.tscn")
		Engine.time_scale = 1
	
	paused = !paused
