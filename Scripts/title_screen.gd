extends Control

var center : Vector2
@onready var node = $Control
@onready var fade_rect := $FadeRect

func _ready() -> void:
	# calculate center of the screen
	center = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y / 2)

	# Start fully black, then fade in like Assassin’s Creed
	fade_rect.modulate.a = 1.0
	var fade_in = create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 0.0, 3.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _process(delta):
	var tween = node.create_tween()
	var offset = center - get_global_mouse_position() * 0.1
	tween.tween_property(node, "position", offset, 1.0)

	if Input.is_action_just_pressed("ui_accept"):
		$CPUParticles2D.emitting = !$CPUParticles2D.emitting

func _on_start_pressed() -> void:
	$Click.play()
	Globals.next_scene = "res://Scenes/test_scene.tscn"

	# Assassin’s Creed style fade-out
	var fade_out = create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, 3.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await fade_out.finished
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
