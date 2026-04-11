extends Control
## Scene for displaying opening logos, placards, or other images before a game.

## Defines the path to the next scene.
@export_file("*.tscn") var next_scene_path: String
## The list of images to show in the opening sequence.
@export var images: Array[Texture2D]
@export_group("Animation")
## The time to fade-in the next image.
@export var fade_in_time: float = 0.2
## The time to fade-out the previous image.
@export var fade_out_time: float = 0.2
## The time to keep an image visible after fade-in and before fade-out.
@export var visible_time: float = 1.6
@export_group("Transition")
## The delay before starting the first fade-in animation once ready.
@export var start_delay: float = 0.5
## The delay after ending the last fade-in animation before loading the next scene.
@export var end_delay: float = 0.5
## If true, show a loading screen if the next scene is not yet ready.
@export var show_loading_screen: bool = false

var _tween: Tween
var _next_image_index: int = 0

@onready var _container: MarginContainer = $MarginContainer


func _ready() -> void:
	SceneLoader.load_scene(next_scene_path, true)
	_add_textures_to_container(images)
	_transition_in()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("ui_cancel"):
		_load_next_scene()
	elif event.is_action_released("ui_accept") or event.is_action_released("ui_select"):
		_show_next_image(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.is_pressed():
		_show_next_image(false)


func _add_textures_to_container(textures: Array[Texture2D]) -> void:
	for texture in textures:
		var texture_rect: TextureRect = TextureRect.new()
		texture_rect.texture = texture
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.modulate.a = 0.0
		_container.call_deferred("add_child", texture_rect)


func _transition_in() -> void:
	await get_tree().create_timer(start_delay).timeout
	if _next_image_index == 0:
		_show_next_image()


func _transition_out() -> void:
	await get_tree().create_timer(end_delay).timeout
	_load_next_scene()


func _show_next_image(animated: bool = true) -> void:
	_hide_previous_image()
	if _next_image_index >= images.size():
		if animated:
			_transition_out()
		else:
			_load_next_scene()
		return
	var texture_rect := _container.get_child(_next_image_index) as TextureRect
	if animated:
		_tween = create_tween()
		_tween.tween_property(texture_rect, "modulate:a", 1.0, fade_in_time)
		await _tween.finished
	else:
		texture_rect.modulate.a = 1.0
	_next_image_index += 1
	_wait_and_fade_out(texture_rect)


func _hide_previous_image() -> void:
	if _tween and _tween.is_running():
		_tween.stop()
	if images.size() == 0:
		return
	var current_image := _container.get_child(_next_image_index - 1) as TextureRect
	if current_image:
		current_image.modulate.a = 0.0


func _wait_and_fade_out(texture_rect: TextureRect) -> void:
	var compare_next_index := _next_image_index
	await get_tree().create_timer(visible_time).timeout
	if compare_next_index != _next_image_index:
		return
	_tween = create_tween()
	_tween.tween_property(texture_rect, "modulate:a", 0.0, fade_out_time)
	await _tween.finished
	_show_next_image.call_deferred()


func _load_next_scene() -> void:
	var status := SceneLoader.get_status()
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		SceneLoader.change_scene_to_resource()
	elif show_loading_screen: # FIXME: SceneLoader should handle this
		SceneLoader.change_scene_to_loading_screen()
	else:
		await SceneLoader.scene_loaded
		SceneLoader.change_scene_to_resource()
