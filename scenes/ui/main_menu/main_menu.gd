extends Control

## The scene to open when a player clicks the 'Options' button.
@export var options_packed_scene: PackedScene
## The scene to open when a player clicks the 'Credits' button.
@export var credits_packed_scene: PackedScene

@onready var _new_game_button: Button = %NewGameButton
@onready var _options_button: Button = %OptionsButton
@onready var _credits_button: Button = %CreditsButton
@onready var _exit_button: Button = %ExitButton


func _ready() -> void:
    _hide_exit_for_web()
    _hide_options_if_unset()
    _hide_credits_if_unset()
    _hide_new_game_if_unset()


func _hide_exit_for_web() -> void:
    if OS.has_feature("web"):
        _exit_button.hide()


func _hide_new_game_if_unset() -> void:
    pass
    # if get_game_scene_path().is_empty():
    # 	_new_game_button.hide()


func _hide_options_if_unset() -> void:
    if options_packed_scene == null:
        _options_button.hide()


func _hide_credits_if_unset() -> void:
    if credits_packed_scene == null:
        _credits_button.hide()
