extends Node
## Autoload class for loading scenes with an optional loading screen.

signal scene_loaded

## Path to the loading screen to display to players while loading a scene.
@export_file("*.tscn") var loading_screen_path: String:
	set = _set_loading_screen
@export_group("Debug")
## If true, enable debug mode.
@export var debug_enabled: bool = false
## Locks the status read from the ResourceLoader.
@export var debug_lock_status: ResourceLoader.ThreadLoadStatus
## Locks the progress read from the ResourceLoader.
@export_range(0, 1) var debug_lock_progress: float = 0.0

var _loading_screen: PackedScene
var _scene_path: String
var _loaded_resource: PackedScene
var _background_loading: bool


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	var status := get_status()
	match (status):
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
		ResourceLoader.THREAD_LOAD_LOADED:
			scene_loaded.emit()
			set_process(false)
			if not _background_loading:
				change_scene_to_resource()


func get_status() -> ResourceLoader.ThreadLoadStatus:
	if debug_enabled:
		return debug_lock_status
	if not _check_scene_path():
		return ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
	return ResourceLoader.load_threaded_get_status(_scene_path)


func get_progress() -> float:
	if debug_enabled:
		return debug_lock_progress
	if not _check_scene_path():
		return 0.0
	var progress_array: Array = []
	ResourceLoader.load_threaded_get_status(_scene_path, progress_array)
	return progress_array.pop_back()


func get_resource() -> PackedScene:
	if not _check_scene_path():
		return
	if ResourceLoader.has_cached(_scene_path):
		_loaded_resource = ResourceLoader.load(_scene_path)
		return _loaded_resource
	# This will block the calling thread until the resource is loaded
	var current_loaded_resource := ResourceLoader.load_threaded_get(_scene_path)
	if current_loaded_resource != null:
		_loaded_resource = current_loaded_resource
	return _loaded_resource


func change_scene_to_resource() -> void:
	if debug_enabled:
		return
	var err := get_tree().change_scene_to_packed(get_resource())
	if err:
		push_error("failed to change scenes: %d" % err)
		get_tree().quit()


func change_scene_to_loading_screen() -> void:
	_background_loading = false
	var err := get_tree().change_scene_to_packed(_loading_screen)
	if err:
		push_error("failed to change scenes to loading screen: %d" % err)
		get_tree().quit()


func is_loading_scene(scene_path: String) -> bool:
	return _scene_path == scene_path


func load_scene(scene_path: String, in_background: bool = false) -> void:
	if scene_path == null or scene_path.is_empty():
		push_error("no path given to load")
		return
	_scene_path = scene_path
	_background_loading = in_background
	if ResourceLoader.has_cached(_scene_path):
		scene_loaded.emit.call_deferred()
		if not _background_loading:
			change_scene_to_resource()
		return
	ResourceLoader.load_threaded_request(_scene_path)
	set_process(true)
	if _check_loading_screen() and not _background_loading:
		change_scene_to_loading_screen()


func reload_current_scene() -> void:
	get_tree().reload_current_scene()


func _check_scene_path() -> bool:
	if _scene_path == null or _scene_path == "":
		push_warning("scene path is empty")
		return false
	return true


func _check_loading_screen() -> bool:
	if _loading_screen == null:
		push_warning("loading screen is not set")
		return false
	return true


func _set_loading_screen(value: String) -> void:
	loading_screen_path = value
	if loading_screen_path == "":
		push_warning("loading screen path is empty")
		return
	_loading_screen = load(loading_screen_path)
