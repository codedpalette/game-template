@tool
extends Control

@export var input_scroll_speed: float = 10.0

var _line_number: float = 0.0

@onready var credits_label: RichTextLabel = $CreditsLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not visible:
		return
	var input_axis := Input.get_axis("ui_up", "ui_down")
	if abs(input_axis) > 0.5:
		_line_number += input_axis * delta * input_scroll_speed
		var max_lines := credits_label.get_line_count() - credits_label.get_visible_line_count()
		_line_number = clamp(_line_number, 0.0, max_lines)
		credits_label.scroll_to_line(roundi(_line_number))


func _on_visibility_changed() -> void:
	if visible:
		credits_label.scroll_to_line(0)
		credits_label.grab_focus()
