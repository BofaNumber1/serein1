extends CanvasLayer

@onready var fade_rect := $FadeRect
@onready var click_sound := $Click
@onready var hover_sound := $Hover

func _ready() -> void:
	# Ensure the FadeRect is black, full screen, and starts fully visible
	fade_rect.color = Color.BLACK
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.modulate.a = 1.0

	# Wait a frame to ensure rendering is ready before fade-in
	await get_tree().process_frame

	# Fade in over 2.0 seconds
	var fade_in = create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 0.0, 2.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		$CPUParticles2D.emitting = !$CPUParticles2D.emitting

func _on_start_pressed() -> void:
	click_sound.play()
	Globals.next_scene = "res://Scenes/test_scene.tscn"

	# Fade out over 4 seconds
	var fade_out = create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, 4.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await fade_out.finished
	await get_tree().create_timer(0.1).timeout  # Ensures fade visually registers
	get_tree().change_scene_to_packed(Globals.loading_screen)
	print("Start Pressed")

func _on_setting_pressed() -> void:
	click_sound.play()

	# Fade out over 4 seconds
	var fade_out = create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, 4.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await fade_out.finished
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")
	print("Settings Pressed")

func _on_quit_pressed() -> void:
	click_sound.play()
	get_tree().quit()
	print("Quit Pressed")

func _on_start_mouse_entered() -> void:
	hover_sound.stop()
	hover_sound.play()

func _on_settings_mouse_entered() -> void:
	hover_sound.stop()
	hover_sound.play()

func _on_quit_mouse_entered() -> void:
	hover_sound.stop()
	hover_sound.play()
