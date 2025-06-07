extends Control

func _ready() -> void:
	visible = true
	get_tree().paused = false  # Unpause for UI interaction

func _on_volume_value_changed(value):
	AudioServer.set_bus_volume_db(0, value/10)

func _on_mute_toggled(toggled_on):
	AudioServer.set_bus_mute(0, toggled_on)

func _on_resolutions_item_selected(index):
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600, 900))
		2:
			DisplayServer.window_set_size(Vector2i(1280, 720))

func _on_back_to_menu_pressed() -> void:
	# Set flag to show pause menu after scene change
	Globals.show_pause_menu = true
	# Load main level
	var error = get_tree().change_scene_to_file(Globals.next_scene)
	if error != OK:
		print("Error loading main level: ", error, " Path: ", Globals.next_scene)
	else:
		print("Main level loaded")
