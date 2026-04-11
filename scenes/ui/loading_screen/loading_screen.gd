class_name LoadingScreen
extends CanvasLayer
## Scene for displaying the progress of a loading scene to the player.

enum StallStage { STARTED, WAITING, STILL_WAITING, GIVE_UP }

const STALLED_ON_WEB = "\nIf running in a browser, try clicking out of the window, 
and then click back into the window. It might unstick.\nLastly, you may try refreshing the page.\n\n"

## Delay between updating the message in the window during stalled periods.
@export_range(5, 60, 0.5, "or_greater") var state_change_delay: float = 15.0
@export_group("State Messages")
@export_subgroup("In Progress")
## Default text to show when loading.
@export var in_progress: String = "Loading..."
## Next text to show when loading has stalled.
@export var in_progress_waiting: String = "Still Loading..."
## Last text to show when loading has stalled.
@export var in_progress_still_waiting: String = "Still Loading... (%d seconds)"
@export_subgroup("Completed")
## Default text to show when loading has completed.
@export var complete: String = "Loading Complete!"
## Next text to show if opening the scene has stalled.
@export var complete_waiting: String = "Any Moment Now..."
## Last text to show if opening the scene has stalled.
@export var complete_still_waiting: String = "Any Moment Now... (%d seconds)"

var _stall_stage: StallStage = StallStage.STARTED
var _loading_complete: bool = false
var _loading_progress: float = 0.0:
    set(value):
        var value_changed := _loading_progress != value
        _loading_progress = value
        if value_changed:
            _progress_bar.value = _loading_progress
            _reset_loading_stage()
var _loading_start_time: int
# See https://github.com/godotengine/godot/issues/77643 for why this is done this way.
var _scene_loader: SceneLoaderClass = SceneLoader

@onready var _error_message: AcceptDialog = $Control/ErrorMessage
@onready var _stalled_message: ConfirmationDialog = $Control/StalledMessage
@onready var _progress_bar: ProgressBar = $Control/VBoxContainer/ProgressBar
@onready var _progress_label: Label = $Control/VBoxContainer/ProgressLabel
@onready var _loading_timer: Timer = $LoadingTimer


func _ready() -> void:
    _reset_loading_stage()
    _reset_loading_start_time()


func _process(_delta: float) -> void:
    var status := _scene_loader.get_status()
    match (status):
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            _update_scene_loading_progress()
            _update_progress_messaging()
        ResourceLoader.THREAD_LOAD_LOADED:
            _set_scene_loading_complete()
            _update_progress_messaging()
        ResourceLoader.THREAD_LOAD_FAILED:
            _error_message.dialog_text = "Loading Error: %d" % status
            _error_message.popup()
            set_process(false)
        ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            _hide_popups()
            set_process(false)


func reset() -> void:
    show()
    _reset_loading_stage()
    _reset_scene_loading_progress()
    _reset_loading_start_time()
    _hide_popups()
    set_process(true)


func close() -> void:
    set_process(false)
    _hide_popups()
    hide()


func _update_scene_loading_progress() -> void:
    var new_progress := _scene_loader.get_progress()
    if new_progress > _loading_progress:
        _loading_progress = new_progress


func _set_scene_loading_complete() -> void:
    _loading_progress = 1.0
    _loading_complete = true


func _reset_scene_loading_progress() -> void:
    _loading_progress = 0.0
    _loading_complete = false


func _reset_loading_stage() -> void:
    _stall_stage = StallStage.STARTED
    _loading_timer.start(state_change_delay)


func _reset_loading_start_time() -> void:
    _loading_start_time = Time.get_ticks_msec()


func _update_progress_messaging() -> void:
    _progress_label.text = _get_progress_message()
    if _stall_stage == StallStage.GIVE_UP:
        if _loading_complete:
            _show_scene_switching_error_message()
        else:
            _show_loading_stalled_error_message()
    else:
        _hide_popups()


func _get_progress_message() -> String:
    var progress_message: String
    match _stall_stage:
        StallStage.STARTED:
            if _loading_complete:
                progress_message = complete
            else:
                progress_message = in_progress
        StallStage.WAITING:
            if _loading_complete:
                progress_message = complete_waiting
            else:
                progress_message = in_progress_waiting
        StallStage.STILL_WAITING, StallStage.GIVE_UP:
            if _loading_complete:
                progress_message = complete_still_waiting
            else:
                progress_message = in_progress_still_waiting
    if progress_message.contains("%d"):
        progress_message = progress_message % _get_seconds_waiting()
    return progress_message


func _show_loading_stalled_error_message() -> void:
    if _stalled_message.visible:
        return
    var message: String
    if _loading_progress == 0:
        message = "Stalled at start. You may try waiting or restarting.\n"
    else:
        message = "Stalled at %d%%. You may try waiting or restarting.\n" % (_loading_progress * 100.0)
    if not OS.has_feature("web"):
        message += STALLED_ON_WEB
    _stalled_message.dialog_text = message
    _stalled_message.popup()


func _show_scene_switching_error_message() -> void:
    if _error_message.visible:
        return
    _error_message.dialog_text = "Loading Error: Failed to switch scenes."
    _error_message.popup()


func _get_seconds_waiting() -> int:
    return int((Time.get_ticks_msec() - _loading_start_time) / 1000.0)


func _hide_popups() -> void:
    _error_message.hide()
    _stalled_message.hide()


func _reload_main_scene_or_quit() -> void:
    var main_scene_path: String = ProjectSettings.get_setting("application/run/main_scene")
    var err := get_tree().change_scene_to_file(main_scene_path)
    if err:
        push_error("failed to load main scene: %d" % err)
        get_tree().quit()


func _on_error_message_confirmed() -> void:
    _reload_main_scene_or_quit()


func _on_stalled_message_canceled() -> void:
    _reload_main_scene_or_quit()


func _on_stalled_message_confirmed() -> void:
    _reset_loading_stage()


func _on_loading_timer_timeout() -> void:
    var prev_stage := _stall_stage
    match prev_stage:
        StallStage.STARTED:
            _stall_stage = StallStage.WAITING
            _loading_timer.start(state_change_delay)
        StallStage.WAITING:
            _stall_stage = StallStage.STILL_WAITING
            _loading_timer.start(state_change_delay)
        StallStage.STILL_WAITING:
            _stall_stage = StallStage.GIVE_UP
