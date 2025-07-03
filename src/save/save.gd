extends Node

const SAVEFILE = "user://SAVEFILE.save"

var game_data = {}

func _ready():
	load_data()

func load_data():
	if not FileAccess.file_exists(SAVEFILE):
		game_data = {
			"fullscreen_on": false,
			"vsync_on": false,
			"display_fps": false,
			"max_fps": 0,
			"bloom_on": false,
			"brightness": 1,
			"master_vol": -10,
			"music_vol": -10,
			"sfx_vol": -10,
			"fov": 70,
			"mouse_sens": 0.1,
		}
		save_data()
		return
	
	var file = FileAccess.open(SAVEFILE, FileAccess.READ)
	if file:
		game_data = file.get_var()
		file.close()

func save_data():
	var file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
	if file:
		file.store_var(game_data)
		file.close()
