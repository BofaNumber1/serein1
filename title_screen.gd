extends Control



func _ready():
	pass



func _process(delta):
	pass


func _on_start_pressed() -> void:
	Globals.next_scene = "res://main_level.tscn"
	get_tree().change_scene_to_packed(Globals.loading_screen)
	print("Start Pressed")


func _on_setting_pressed() -> void:
	print("Settings Pressed")


func _on_quit_pressed() -> void:
	print("Quit Pressed")
