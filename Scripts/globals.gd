extends Node

var loading_screen = preload("res://Scenes/loading_screen.tscn")
var settings_screen : String = "res://Scenes/settings.tscn"
var pause_settings : String = "res://Scenes/pause_settings.tscn"
var next_scene : String = "res://Scenes/main_level.tscn"
var title_screen : String = "res://Scenes/title_screen.tscn"
var pause_screen : String = "res://Scenes/pause_screen.tscn"
var show_pause_menu: bool = false  # Flag to show pause menu after scene change
