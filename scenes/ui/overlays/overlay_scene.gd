@tool
class_name OverlayScene
extends OverlayWindow

@export var packed_scene: PackedScene:
    set(value):
        packed_scene = value
        if is_inside_tree():
            for child in scene_container.get_children():
                child.queue_free()
            if packed_scene:
                _instance = packed_scene.instantiate()
                scene_container.add_child(_instance)

var _instance: Node

@onready var scene_container: Container = %SceneContainer


func _ready() -> void:
    super()
    packed_scene = packed_scene
