@tool
class_name OverlayConfirmation
extends OverlayWindow

signal confirmed

@export var confirm_button_text: String = "Confirm":
    set(value):
        confirm_button_text = value
        if update_content and is_inside_tree():
            confirm_button.text = confirm_button_text

@onready var confirm_button: Button = %ConfirmButton


func _ready() -> void:
    confirm_button_text = confirm_button_text


func confirm() -> void:
    confirmed.emit()
    hide()


func _on_confirm_button_pressed() -> void:
    confirm()
