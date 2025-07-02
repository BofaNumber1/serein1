extends Control
class_name Settings

@onready var exit = $VBoxContainer/Exit as Button





func _on_exit_pressed() -> void:
	Globals.title_screen = "res://Scenes/UI/main_menu.tscn"
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
	print("Back to menu Pressed")
