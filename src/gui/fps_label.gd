extends Label

func _ready():
	if GlobalSettings.display_fps:
		show()
	else:
		hide()

func _process(_delta):
	if GlobalSettings.display_fps:
		text = "FPS: %s" % Engine.get_frames_per_second()
	else:
		hide()
