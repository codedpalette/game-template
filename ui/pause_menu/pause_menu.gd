@tool
extends OverlayWindow

@export var options_menu_scene: PackedScene
@export_file("*.tscn") var main_menu_scene_path: String

var _open_window: Control = null
var _ignore_first_cancel := false

@onready var _restart_confirmation: OverlayConfirmation = %RestartConfirmation
@onready var _main_menu_confirmation: OverlayConfirmation = %MainMenuConfirmation
@onready var _exit_confirmation: OverlayConfirmation = %ExitConfirmation
@onready var _menu_buttons: BoxContainer = %MenuButtons
@onready var _options_button: Button = %OptionsButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _exit_button: Button = %ExitButton


func _ready() -> void:
    _exit_button.visible = !OS.has_feature("web")
    _options_button.visible = options_menu_scene != null
    _main_menu_button.visible = !main_menu_scene_path.is_empty()
    _restart_confirmation.confirmed.connect(_on_restart_confirmation_confirmed)
    _main_menu_confirmation.confirmed.connect(_on_main_menu_confirmation_confirmed)
    _exit_confirmation.confirmed.connect(_on_exit_confirmation_confirmed)
    super._ready()


func close_window() -> void:
    if _open_window != null:
        _open_window.hide()
        _open_window = null


func _on_window_shown() -> void:
    super._on_window_shown()
    if Input.is_action_pressed("ui_cancel"):
        _ignore_first_cancel = true


func _handle_cancel_input() -> void:
    if _ignore_first_cancel:
        _ignore_first_cancel = false
        return
    if _open_window != null:
        close_window()
    else:
        super._handle_cancel_input()


func _on_restart_button_pressed() -> void:
    _show_window(_restart_confirmation)


func _on_options_button_pressed() -> void:
    _load_and_show_menu(options_menu_scene)


func _on_main_menu_button_pressed() -> void:
    _show_window(_main_menu_confirmation)


func _on_exit_button_pressed() -> void:
    _show_window(_exit_confirmation)


func _on_restart_confirmation_confirmed() -> void:
    SceneLoader.reload_current_scene()
    hide()


func _on_main_menu_confirmation_confirmed() -> void:
    _load_scene(main_menu_scene_path)


func _on_exit_confirmation_confirmed() -> void:
    get_tree().quit()


func _show_window(window: Control) -> void:
    _disable_focus.call_deferred()
    window.show()
    _open_window = window
    await window.hidden
    _open_window = null
    _enable_focus.call_deferred()


func _load_and_show_menu(scene: PackedScene) -> void:
    var window_instance: Control = scene.instantiate()
    window_instance.visible = false
    add_sibling.call_deferred(window_instance)
    await _show_window(window_instance)
    window_instance.queue_free()


func _disable_focus() -> void:
    for child in _menu_buttons.get_children():
        if child is Control:
            (child as Control).focus_mode = FOCUS_NONE


func _enable_focus() -> void:
    for child in _menu_buttons.get_children():
        if child is Control:
            (child as Control).focus_mode = FOCUS_ALL


func _load_scene(scene_path: String) -> void:
    _scene_tree.paused = false
    SceneLoader.load_scene(scene_path)
