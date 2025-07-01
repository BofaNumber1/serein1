extends Node

@onready var music: AudioStreamPlayer = $"../AudioStreamPlayer"
@onready var fade_rect: ColorRect = $"../FadeRect"
@onready var tip_panel: Panel = $"../CanvasLayer/TipPanel"
@onready var tip_label: Label = tip_panel.get_node("TipLabel")

var tips = [
	"Don't forget to take breaks from time to time!",
	"Use rooftops to evade guards.",
	"Don't be afraid to slide under tables or swing off poles.",
	"Remember to deliver your package!",
]

var scene_to_load: PackedScene = preload("res://Scenes/test_scene.tscn")

func _ready():
	randomize()
	# Start fully transparent
	tip_label.modulate.a = 0.0
	tip_panel.modulate.a = 0.0
	
	show_random_tip()
	fade_in_screen_and_music()
	fade_in_tip_panel()
	start_tip_loop()
	load_game_scene_async()

func show_random_tip():
	tip_label.text = tips[randi() % tips.size()]

func fade_in_tip_panel():
	var tween = create_tween()
	tween.tween_property(tip_panel, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func fade_out_tip_panel():
	var tween = create_tween()
	tween.tween_property(tip_panel, "modulate:a", 0.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func fade_in_tip():
	var tween = create_tween()
	tween.tween_property(tip_label, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func fade_out_tip():
	var tween = create_tween()
	tween.tween_property(tip_label, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func fade_tip_out_in() -> void:
	await fade_out_tip()
	show_random_tip()
	await fade_in_tip()

func start_tip_loop():
	fade_in_tip()
	change_tip_loop()  # Start looping tip changes asynchronously

func change_tip_loop() -> void:
	await get_tree().create_timer(5.0).timeout
	while true:
		await fade_tip_out_in()
		await get_tree().create_timer(5.0).timeout

func fade_in_screen_and_music():
	fade_rect.color.a = 1.0
	music.volume_db = -80.0
	music.play()

	var tween = create_tween()
	tween.parallel()
	tween.tween_property(music, "volume_db", -25.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "color:a", 0.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func fade_out_screen_and_music():
	var tween = create_tween()
	tween.parallel()
	tween.tween_property(music, "volume_db", -80.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "color:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_out_tip_panel()
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
