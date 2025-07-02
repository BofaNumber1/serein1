extends Control

var center : Vector2
@onready var node = $Control


func _ready() -> void:
	visible = true
	get_tree().paused = false  # Unpause for UI interaction
	$MarginContainer/VBoxContainer/Resolutions.clear()
	$MarginContainer/VBoxContainer/Resolutions.add_item("1920 x 1080")
	$MarginContainer/VBoxContainer/Resolutions.add_item("1600 x 900")
	$MarginContainer/VBoxContainer/Resolutions.add_item("1280 x 720")
	center = Vector2(get_viewport_rect().size.x/2, get_viewport_rect().size.y/2)

func _process(delta):
	var tween = node.create_tween()
	var offset = center - get_global_mouse_position() * 0.1
	tween.tween_property(node, "position",offset,1.0)
	if Input.is_action_just_pressed("ui_accept"):
		$CPUParticles2D.emitting = !$CPUParticles2D.emitting

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
	# Set flag to show pause menu after scene change
	Globals.show_pause_menu = true
	# Load main level
	var error = get_tree().change_scene_to_file(Globals.next_scene)
	if error != OK:
		print("Error loading main level: ", error, " Path: ", Globals.next_scene)
	else:
		print("Main level loaded")
