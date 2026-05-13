extends CanvasLayer

signal restart_requested
signal title_requested
signal exit_requested

@onready var _restart_btn := $Center/VBox/RestartButton as TextureButton
@onready var _title_btn := $Center/VBox/TitleButton as TextureButton


func show_menu(in_room: bool, in_game: bool = true, can_restart: bool = true) -> void:
	_restart_btn.visible = in_room and can_restart
	_title_btn.visible = in_game
	visible = true
	get_tree().paused = true


func hide_menu() -> void:
	visible = false
	get_tree().paused = false


func _on_continue_pressed() -> void:
	hide_menu()


func _on_restart_pressed() -> void:
	hide_menu()
	restart_requested.emit()


func _on_title_pressed() -> void:
	hide_menu()
	title_requested.emit()


func _on_exit_pressed() -> void:
	hide_menu()
	exit_requested.emit()
