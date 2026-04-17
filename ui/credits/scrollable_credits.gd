@tool
extends ScrollContainer

## Scroll speed when using input devices (keyboard/joystick) to scroll, in pixels per second.
@export var input_scroll_speed: float = 200.0
## If true, scroll automatically when the node is visible.
@export var use_auto_scroll: bool = false
## Speed of the auto scroll, in pixels per second.
@export var auto_scroll_speed: float = 100.0

var _scroll_position: float = 0

@onready var credits_label: RichTextLabel = $CreditsLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    visibility_changed.connect(_on_visibility_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    if Engine.is_editor_hint() or not visible:
        return
    var input_axis := Input.get_axis("ui_up", "ui_down")
    var scroll_speed: float
    if abs(input_axis) > 0.5:
        scroll_speed = input_scroll_speed * input_axis
    elif use_auto_scroll:
        scroll_speed = auto_scroll_speed
    if scroll_speed != 0:
        if abs(scroll_vertical - _scroll_position) > 1:
            _scroll_position = scroll_vertical
        _scroll_position += delta * scroll_speed
        _scroll_position = clamp(_scroll_position, 0.0, get_v_scroll_bar().max_value)
        scroll_vertical = roundi(_scroll_position)


func _on_visibility_changed() -> void:
    if visible:
        _scroll_position = 0
        scroll_vertical = 0
        credits_label.grab_focus()
