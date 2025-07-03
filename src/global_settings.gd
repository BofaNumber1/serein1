extends Node

var Save = preload("res://src/save/save.gd").new() # Or remove this if you autoload Save

signal fps_display_changed(enabled: bool)
signal bloom_toggled(value: bool)
signal brightness_updated(value: float)
signal fov_updated(value: float)
signal mouse_sens_updated(value: float)

var display_fps: bool = false

func toggle_fullscreen(toggle: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if toggle else DisplayServer.WINDOW_MODE_WINDOWED
	)
	Save.game_data.fullscreen_on = toggle
	Save.save_data()

func toggle_vsync(toggle: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggle else DisplayServer.VSYNC_DISABLED
	)
	Save.game_data.vsync_on = toggle
	Save.save_data()

func toggle_fps_display(on: bool) -> void:
	display_fps = on
	emit_signal("fps_display_changed", on)
	Save.game_data.display_fps = on
	Save.save_data()

func set_max_fps(value: int) -> void:
	Engine.max_fps = value if value < 500 else 0
	Save.game_data.max_fps = Engine.max_fps if value < 500 else 500
	Save.save_data()

func toggle_bloom(value: bool) -> void:
	emit_signal("bloom_toggled", value)
	Save.game_data.bloom_on = value
	Save.save_data()

func update_brightness(value: float) -> void:
	emit_signal("brightness_updated", value)
	Save.game_data.brightness = value
	Save.save_data()

func update_master_vol(vol: float) -> void:
	AudioServer.set_bus_volume_db(0, vol)
	Save.game_data.master_vol = vol
	Save.save_data()

func update_music_vol(vol: float) -> void:
	AudioServer.set_bus_volume_db(1, vol)
	Save.game_data.music_vol = vol
	Save.save_data()

func update_sfx_vol(vol: float) -> void:
	AudioServer.set_bus_volume_db(2, vol)
	Save.game_data.sfx_vol = vol
	Save.save_data()

func update_fov(value: float) -> void:
	emit_signal("fov_updated", value)
	Save.game_data.fov = value
	Save.save_data()

func update_mouse_sens(value: float) -> void:
	emit_signal("mouse_sens_updated", value)
	Save.game_data.mouse_sens = value
	Save.save_data()
