extends Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _process(delta: float) -> void:
    sprite.rotation += delta
