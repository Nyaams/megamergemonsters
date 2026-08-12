extends Node

var restore_session: bool = false


func start_new_game() -> void:
	restore_session = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func continue_game() -> void:
	restore_session = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
