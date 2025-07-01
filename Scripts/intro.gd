extends Node2D

@onready var animation_intro = $AnimationPlayer


func _ready():
	animation_intro.play("fade_in")
	get_tree().create_timer(3).timeout.connect(fade_out)
	

func fade_out():
	animation_intro.play("fade_out")
	get_tree().create_timer(3).timeout.connect(title_screen)
	

func title_screen():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
