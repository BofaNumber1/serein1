extends Control

func _ready():
	$MarginContainer/VBoxContainer/Resolutions.clear()
	$MarginContainer/VBoxContainer/Resolutions.add_item("1920 x 1080")
	$MarginContainer/VBoxContainer/Resolutions.add_item("1600 x 900")
	$MarginContainer/VBoxContainer/Resolutions.add_item("1280 x 720")	


func _on_volume_value_changed(value):
	AudioServer.set_bus_volume_db(0, value/10)


func _on_mute_toggled(toggled_on):
	AudioServer.set_bus_mute(0, toggled_on)


func _on_resolutions_item_selected(index):
	# Set the window mode first
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Small delay to ensure window mode is applied before resizing
	await get_tree().process_frame

	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600, 900))
		2:
			DisplayServer.window_set_size(Vector2i(1280, 720))



func _on_back_to_menu_pressed() -> void:
	Globals.title_screen = "res://Scenes/title_screen.tscn"
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
	print("Back to menu Pressed")
	
