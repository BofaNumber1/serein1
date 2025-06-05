extends Control



func _ready():
	pass



func _process(delta):
	pass


func _on_start_pressed() -> void:
	Globals.next_scene = "res://Scenes/main_level.tscn"
	get_tree().change_scene_to_packed(Globals.loading_screen)
	print("Resume Pressed")


func _on_setting_pressed() -> void:
	Globals.settings_screen = "res://Scenes/settings.tscn"
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")
	print("Settings Pressed")


func _on_quit_pressed() -> void:
	Globals.title_screen = "res://Scenes/title_screen.tscn"
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
	print("Quit Pressed")
