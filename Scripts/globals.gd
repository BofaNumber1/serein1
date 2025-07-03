extends Node

var loading_screen = preload("res://Scenes/Loading Screen/3Dloading_screen.tscn")
var settings_screen : String = "res://src/gui/settings_menu.tscn"
var pause_settings : String = "res://Scenes/pause_settings.tscn"
var next_scene : String = "res://Scenes/test_scene.tscn"
var title_screen : String = "res://Scenes/UI/main_menu.tscn"
var pause_screen : String = "res://Scenes/pause_screen.tscn"
var show_pause_menu: bool = false  # Flag to show pause menu after scene change
