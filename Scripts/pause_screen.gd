extends Control

func _ready() -> void:
	# Hide pause menu on start
	visible = false
	$AudioStreamPlayer.stream_paused
	$AnimationPlayer.play("RESET")
	get_tree().paused = false
	# Store main level path
	if not Globals.next_scene:
		Globals.next_scene = get_tree().current_scene.scene_file_path
		print("Stored main level: ", Globals.next_scene)

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	await $AnimationPlayer.animation_finished
	visible = false

func pause():
	visible = true
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	$AudioStreamPlayer.play()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if not get_tree().paused:
			pause()
		else:
			resume()

func _on_resume_pressed() -> void:
	resume()
	$AudioStreamPlayer.stop()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	visible = false
	get_tree().reload_current_scene()

func _on_setting_pressed() -> void:
	# Hide pause menu and unpause
	visible = false
	get_tree().paused = false
	var error = get_tree().change_scene_to_file(Globals.pause_settings)
	if error != OK:
		print("Error loading pause settings: ", error)
	else:
		print("Pause settings loaded")

func _on_back_to_main_menu_pressed() -> void:
	visible = false
	get_tree().paused = false
	var error = get_tree().change_scene_to_file(Globals.title_screen)
	if error != OK:
		print("Error loading title screen: ", error)

func _on_back_to_menu_pressed() -> void:
	# For submenus; re-show pause menu
	visible = true
	get_tree().paused = true
	print("Back to pause menu")
