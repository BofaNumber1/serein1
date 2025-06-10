extends Control



func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		$CPUParticles2D.emitting = !$CPUParticles2D.emitting


func _on_start_pressed() -> void:
	$Click.play()
	Globals.next_scene = "res://Scenes/main_level.tscn"
	get_tree().change_scene_to_packed(Globals.loading_screen)
	print("Start Pressed")


func _on_setting_pressed() -> void:
	$Click.play()
	Globals.settings_screen = "res://Scenes/settings.tscn"
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")
	print("Settings Pressed")


func _on_quit_pressed() -> void:
	$Click.play()
	get_tree().quit()
	print("Quit Pressed")


func _on_start_mouse_entered() -> void:
	$Hover.play()


func _on_setting_mouse_entered() -> void:
	$Hover.play()


func _on_quit_mouse_entered() -> void:
	$Hover.play()
