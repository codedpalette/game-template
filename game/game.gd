extends Node

@onready var sprite: Sprite2D = $World/Sprite2D


func _process(delta: float) -> void:
    sprite.rotation += delta
