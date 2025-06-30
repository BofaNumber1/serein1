extends Node

@onready var music: AudioStreamPlayer = $"../AudioStreamPlayer"
@onready var fade_rect: ColorRect = $"../FadeRect"

var scene_to_load: PackedScene = preload("res://Scenes/test_scene.tscn")

func _ready():
	fade_in_screen_and_music()
	load_game_scene_async()

func fade_in_screen_and_music():
	# Start with black screen fully opaque
	fade_rect.color.a = 1.0
	music.volume_db = -80.0
	music.play()

	# Tween to fade music volume to -25 dB and screen alpha to 0 (transparent)
	var tween = create_tween()
	tween.parallel() # tween both at the same time
	tween.tween_property(music, "volume_db", -25.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "color:a", 0.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func fade_out_screen_and_music():
	var tween = create_tween()
	tween.parallel()
	tween.tween_property(music, "volume_db", -80.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "color:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	music.stop()

func load_game_scene_async():
	var scene_path = scene_to_load.resource_path
	ResourceLoader.load_threaded_request(scene_path)
	await get_tree().process_frame

	while true:
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		await get_tree().process_frame

	print("Scene loaded in background. Waiting 15 seconds...")
	await get_tree().create_timer(15.0).timeout

	await fade_out_screen_and_music()

	var loaded_scene = ResourceLoader.load_threaded_get(scene_path)
	get_tree().change_scene_to_packed(loaded_scene)
