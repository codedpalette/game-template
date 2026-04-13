@tool
extends Label

const DEFAULT_TITLE = "Title"

## If true, the label will automatically update its text based on project settings.
@export var auto_update := true


func _ready() -> void:
    if auto_update:
        _update_label()


func _update_label() -> void:
    var config_name: String = ProjectSettings.get_setting("application/config/name", DEFAULT_TITLE)
    if config_name.is_empty():
        config_name = DEFAULT_TITLE
    text = config_name
