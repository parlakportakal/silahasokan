extends Control

# Oyun sahnesini Inspector'dan değiştirebilirsin.
@export_file("*.tscn") var game_scene_path: String = "res://Scenes/main.tscn"
@export_file("*.tscn") var level_2_scene_path: String = "res://Scenes/el_banyo.tscn"
@export_file("*.tscn") var level_3_scene_path: String = "res://Scenes/el_kanyon.tscn"
var selected_mode: String = "online"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%OnlineButton.grab_focus()

func _on_online_pressed() -> void:
	_show_map_selection("online")

func _on_solo_pressed() -> void:
	_show_map_selection("solo")

func _show_map_selection(mode: String) -> void:
	selected_mode = mode
	%OnlineButton.hide()
	%SoloButton.hide()
	%QuitButton.hide()
	%MapSelection.show()
	%MapHint.visible = mode == "online"
	%Status.text = ""
	%Level1Button.grab_focus()

func _on_back_pressed() -> void:
	%MapSelection.hide()
	%OnlineButton.show()
	%SoloButton.show()
	%QuitButton.show()
	%Status.text = ""
	%OnlineButton.grab_focus()

func _on_level_1_pressed() -> void:
	_open_game(game_scene_path)

func _on_level_2_pressed() -> void:
	_open_game(level_2_scene_path)

func _on_level_3_pressed() -> void:
	_open_game(level_3_scene_path)

func _open_game(scene_path: String) -> void:
	get_tree().set_meta("launch_mode", selected_mode)
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		get_tree().remove_meta("launch_mode")
		%Status.text = "Oyun sahnesi açılamadı: " + error_string(error)

func _on_quit_pressed() -> void:
	get_tree().quit()
