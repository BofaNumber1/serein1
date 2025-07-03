extends Node

var fullscreen_on := false
var vsync_on := false
var display_fps := false
var max_fps := 0
var bloom_on := false
var brightness := 1.0
var master_vol := -10.0
var fov := 70
var mouse_sens := 0.1

func toggle_fullscreen(on: bool):
	fullscreen_on = on
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)

func toggle_vsync(on: bool):
	vsync_on = on
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED)

func toggle_fps_display(on: bool):
	display_fps = on
	display_fps = on  # And handle the display manually via Label

func set_max_fps(value: int):
	max_fps = value
	Engine.max_fps = value if value > 0 else 0

func toggle_bloom(on: bool):
	bloom_on = on
	# Insert your post-processing bloom logic here, e.g. via WorldEnvironment

func update_brightness(value: float):
	brightness = value
	# Apply brightness using WorldEnvironment if needed

func update_master_vol(value: float):
	master_vol = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)


func update_mouse_sens(value: float):
	mouse_sens = value
	# Save for use by your input/controller logic


func _on_exit_pressed() -> void:
	$Click.play()
	Globals.title_screen = "res://Scenes/UI/main_menu.tscn"
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
	print("Back to menu Pressed")


func _on_exit_mouse_entered() -> void:
	$Hover.play()
