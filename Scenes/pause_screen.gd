extends Control


@onready var main_level = $"res://Scenes/main_level.tscn"

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


func _on_start_pressed() -> void:
	main_level.pause_screen()
	print("Resume Pressed")


func _on_setting_pressed() -> void:
	Globals.pause_settings = "res://Scenes/pause_settings.tscn"
	get_tree().change_scene_to_file("res://Scenes/pause_settings.tscn")
	print("Settings Pressed")

func _on_back_to_menu_pressed() -> void:
	Globals.pause_screen = "res://Scenes/pause_screen.tscn"
	get_tree().change_scene_to_file("res://Scenes/pause_screen.tscn")
	print("Back to menu Pressed")

func _on_quit_pressed() -> void:
	Globals.title_screen = "res://Scenes/title_screen.tscn"
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
	print("Quit Pressed")
