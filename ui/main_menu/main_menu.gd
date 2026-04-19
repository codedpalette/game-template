extends Control

signal sub_menu_opened
signal sub_menu_closed

## Defines the path to the game scene. Hides the play button if empty.
@export_file("*.tscn") var game_scene_path: String
## The scene to open when a player clicks the 'Options' button.
@export var options_packed_scene: PackedScene
## The scene to open when a player clicks the 'Credits' button.
@export var credits_packed_scene: PackedScene
@export var confirm_exit: bool = true
@export var show_loading_screen: bool = false

var _sub_menu: Control

@onready var _menu_container: MarginContainer = %MenuContainer
@onready var _menu_buttons_box_container: BoxContainer = %MenuButtons
@onready var _new_game_button: Button = %NewGameButton
@onready var _options_button: Button = %OptionsButton
@onready var _credits_button: Button = %CreditsButton
@onready var _exit_button: Button = %ExitButton
@onready var _exit_confirmation: OverlayConfirmation = %ExitConfirmation


func _ready() -> void:
    _hide_new_game_if_unset()
    _hide_exit_for_web()
    _hide_options_if_unset()
    _hide_credits_if_unset()


func _input(event: InputEvent) -> void:
    if event.is_action_released("ui_cancel"):
        if _sub_menu:
            _close_sub_menu()
        else:
            try_exit_game()
    if event.is_action_released("ui_accept") and get_viewport().gui_get_focus_owner() == null:
        var capture_focus := _menu_buttons_box_container as Control as CaptureFocus
        if capture_focus:
            capture_focus.focus_first()


func get_game_scene_path() -> String:
    return game_scene_path


func load_game_scene() -> void:
    if show_loading_screen:
        SceneLoader.load_scene(get_game_scene_path())
    else:
        SceneLoader.load_scene(get_game_scene_path(), true)
        await SceneLoader.scene_loaded
        SceneLoader.change_scene_to_resource()


func new_game() -> void:
    load_game_scene()


func try_exit_game() -> void:
    if confirm_exit and not _exit_confirmation.visible:
        _exit_confirmation.show()
    else:
        exit_game()


func exit_game() -> void:
    if OS.has_feature("web"):
        return
    get_tree().quit()


func _hide_new_game_if_unset() -> void:
    if get_game_scene_path().is_empty():
        _new_game_button.hide()


func _hide_exit_for_web() -> void:
    if OS.has_feature("web"):
        _exit_button.hide()


func _hide_options_if_unset() -> void:
    if options_packed_scene == null:
        _options_button.hide()


func _hide_credits_if_unset() -> void:
    if credits_packed_scene == null:
        _credits_button.hide()


func _open_sub_menu(menu: PackedScene) -> Node:
    _sub_menu = menu.instantiate()
    add_child(_sub_menu)
    _menu_container.hide()
    _sub_menu.hidden.connect(_close_sub_menu, CONNECT_ONE_SHOT)
    _sub_menu.tree_exiting.connect(_close_sub_menu, CONNECT_ONE_SHOT)
    sub_menu_opened.emit()
    return _sub_menu


func _close_sub_menu() -> void:
    if _sub_menu == null:
        return
    _sub_menu.queue_free()
    _sub_menu = null
    _menu_container.show()
    sub_menu_closed.emit()


func _on_new_game_button_pressed() -> void:
    new_game()


func _on_options_button_pressed() -> void:
    _open_sub_menu(options_packed_scene)


func _on_credits_button_pressed() -> void:
    _open_sub_menu(credits_packed_scene)


func _on_exit_button_pressed() -> void:
    try_exit_game()


func _on_exit_confirmation_confirmed() -> void:
    exit_game()
