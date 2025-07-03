extends Control
class_name Settings

@onready var exit = $VBoxContainer/Exit as Button





func _on_exit_pressed() -> void:
	$Click.play()
	Globals.title_screen = "res://Scenes/UI/main_menu.tscn"
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
	print("Back to menu Pressed")


func _on_exit_mouse_entered() -> void:
	$Hover.play()
