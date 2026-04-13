@tool
class_name OverlayWindow
extends WindowContainer

@export var pauses_game: bool = false:
    set(value):
        pauses_game = value
        if pauses_game:
            process_mode = PROCESS_MODE_ALWAYS
        else:
            process_mode = PROCESS_MODE_INHERIT
@export var makes_mouse_visible: bool = true
@export var exclusive: bool = true
@export var exclusive_background_color: Color

var _initial_pause_state: bool = false
var _initial_mouse_mode: Input.MouseMode
var _initial_focus_control: Control
var _initial_node_focus_modes: Dictionary[Control, Control.FocusMode]
var _scene_tree: SceneTree
var _exclusive_control_node: ColorRect


func _enter_tree() -> void:
    _scene_tree = get_tree()
    if not visibility_changed.is_connected(_on_visibility_changed):
        visibility_changed.connect(_on_visibility_changed)
    _on_visibility_changed()


func close() -> void:
    if not visible:
        return
    _overlay_window_teardown()
    super.close()


func _on_visibility_changed() -> void:
    if is_visible_in_tree():
        _overlay_window_setup()


func _overlay_window_setup() -> void:
    # May not work, see https://github.com/Maaack/Godot-Game-Template/issues/457
    # FIXME: Verify this with pause menu
    if _scene_tree:
        _initial_pause_state = _scene_tree.paused
    _initial_mouse_mode = Input.mouse_mode
    _initial_focus_control = get_viewport().gui_get_focus_owner()
    if _initial_focus_control:
        _initial_focus_control.release_focus()
    if Engine.is_editor_hint():
        return
    _scene_tree.paused = pauses_game or _initial_pause_state
    if makes_mouse_visible:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if exclusive:
        _unset_focus_modes(_scene_tree.current_scene)
        _exclusive_control_node = ColorRect.new()
        _exclusive_control_node.name = self.name + "ExclusiveControl"
        _exclusive_control_node.color = exclusive_background_color
        _exclusive_control_node.set_anchors_preset(PRESET_FULL_RECT)
        add_sibling.call_deferred(_exclusive_control_node)
        await _exclusive_control_node.draw
        get_parent().move_child(_exclusive_control_node, get_index())


func _overlay_window_teardown() -> void:
    _scene_tree.paused = _initial_pause_state
    Input.mouse_mode = _initial_mouse_mode
    _restore_focus_modes()
    if is_instance_valid(_initial_focus_control) and _initial_focus_control.is_inside_tree():
        _initial_focus_control.grab_focus()
    if _exclusive_control_node:
        _exclusive_control_node.queue_free()
        _exclusive_control_node = null


func _unset_focus_modes(node: Node) -> void:
    for child in node.get_children():
        if child == self:
            continue
        var control := child as Control
        if control:
            _initial_node_focus_modes[control] = control.focus_mode
            control.focus_mode = Control.FOCUS_NONE
        _unset_focus_modes(control)


func _restore_focus_modes() -> void:
    for node in _initial_node_focus_modes:
        if is_instance_valid(node):
            node.focus_mode = _initial_node_focus_modes[node]
    _initial_node_focus_modes.clear()
