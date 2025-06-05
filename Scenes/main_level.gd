extends Node3D
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("main_menu"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://Scenes/pause_screen.tscn")
