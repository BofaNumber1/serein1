extends Node

@onready var music: AudioStreamPlayer = $"../AudioStreamPlayer"
@onready var fade_rect: ColorRect = $"../FadeRect"
@onready var tip_panel: Panel = $"../CanvasLayer/TipPanel"
@onready var tip_label: Label = tip_panel.get_node("TipLabel")
@onready var progress_bar: ProgressBar = $"../CanvasLayer/ProgressBar"

var tips = [
	"Don't forget to play Phoxys haunted delivery.",
	"Use rooftops to evade the opps.",
	"The magical flute is op btw.",
	"Don't do drugs kids!",
	"Timmy is basically Ash Ketchum after Pikachu died LMAO",
	"Don't forget to sub zeke_caesar on yt ;)",
	"Find parkour routes all across the city",
	"Make sure you're having fun!",
]

var scene_to_load: PackedScene = preload("res://Scenes/Levels/test_scene.tscn")

func _ready() -> void:
	randomize()

	# Initialize UI
	tip_label.modulate.a = 0.0
	tip_panel.modulate.a = 0.0
	progress_bar.value = 0
	progress_bar.visible = true
	tip_panel.visible = true

	show_random_tip()

	await fade_in_screen_and_music()

	await fade_in_tip_panel()

	# Start tip loop concurrently
	call_deferred("_tip_loop")

	await load_game_scene_async()

func show_random_tip() -> void:
	tip_label.text = tips[randi() % tips.size()]

func fade_in_tip_panel():
	var tween = create_tween()
	tween.tween_property(tip_panel, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween.finished

func fade_out_tip_panel():
	var tween = create_tween()
	tween.tween_property(tip_panel, "modulate:a", 0.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween.finished

func fade_in_tip():
	var tween = create_tween()
	tween.tween_property(tip_label, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween.finished

func fade_out_tip():
	var tween = create_tween()
	tween.tween_property(tip_label, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween.finished

func fade_tip_out_in() -> void:
	await fade_out_tip()
	show_random_tip()
	await fade_in_tip()

func _tip_loop() -> void:
	await fade_in_tip()
	while true:
		await get_tree().create_timer(5.0).timeout
		await fade_tip_out_in()

func fade_in_screen_and_music() -> void:
	fade_rect.color.a = 1.0
	music.volume_db = -80.0
	music.play()

	var tween = create_tween()
	tween.parallel()
	tween.tween_property(music, "volume_db", -25.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "color:a", 0.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func fade_out_screen_and_music() -> void:
	var tween = create_tween()
	tween.parallel()
	tween.tween_property(music, "volume_db", -80.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "color:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_out_tip_panel()
	await tween.finished
	music.stop()

func load_game_scene_async() -> void:
	var scene_path = scene_to_load.resource_path
	ResourceLoader.load_threaded_request(scene_path)
	await get_tree().process_frame

	while true:
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(scene_path, progress)

		if progress.size() == 2 and progress[1] > 0:
			var pct := float(progress[0]) / float(progress[1]) * 100.0
			progress_bar.value = pct

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break

		await get_tree().process_frame

	# Now loading is done, animate progress bar from current value to 100 over fade duration (2 sec)
	var start_val = progress_bar.value
	var fade_duration = 2.0
	var timer = 0.0

	while timer < fade_duration:
		timer += get_process_delta_time()
		progress_bar.value = lerp(start_val, 100.0, timer / fade_duration)
		await get_tree().process_frame

	# Fade out screen and music, progress bar is full now
	await fade_out_screen_and_music()

	var loaded_scene = ResourceLoader.load_threaded_get(scene_path)
	get_tree().change_scene_to_packed(loaded_scene)
