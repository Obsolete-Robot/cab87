extends DebugPanelModuleController

class_name DebugPanelCameraModule

var _body: VBoxContainer
var _camera: Camera3D
var _spring: Node3D
var _player: Node3D

var _distance: float = 16.0
var _height: float = 4.0
var _pitch_deg: float = -15.0
var _fov: float = 75.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	if DebugPanelService != null:
		DebugPanelService.register_controller(self)
	else:
		push_warning("DebugPanelCameraModule: DebugPanelService not available; module inactive")

func get_module_id() -> StringName:
	return StringName("camera")

func get_module_title() -> String:
	return "Camera"

func get_default_collapsed() -> bool:
	return false

func on_module_registered(handle: DebugPanelModuleHandle) -> void:
	super.on_module_registered(handle)
	_body = handle.get_body_container()
	_discover_nodes()
	_read_from_scene()
	_build_ui()

func on_module_unregistered() -> void:
	super.on_module_unregistered()
	_body = null
	set_process(false)

func _process(_delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_discover_nodes()
		_read_from_scene()
	_update_camera_transform()

func _discover_nodes() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var root := tree.current_scene
	_player = root.get_node_or_null("PlayerCar")
	if _player == null:
		return
	_spring = _player.get_node_or_null("SpringArm3D")
	if _spring == null:
		return
	_camera = _spring.get_node_or_null("Camera3D") as Camera3D

func _read_from_scene() -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	if _spring != null and is_instance_valid(_spring):
		_height = _spring.transform.origin.y
	_distance = _camera.transform.origin.z
	_pitch_deg = _camera.rotation_degrees.x
	_fov = _camera.fov

func _build_ui() -> void:
	if module_handle == null or _body == null:
		return
	module_handle.clear()
	var label := Label.new()
	if _camera != null and is_instance_valid(_camera):
		label.text = "Camera path: %s" % _camera.get_path()
	else:
		label.text = "Camera not found (looking for PlayerCar/SpringArm3D/Camera3D)"
	_body.add_child(label)

	var distance_data := module_handle.create_slider(
		"Distance", 4.0, 60.0, 0.25, _distance,
		Callable(self, "_on_distance_changed"),
		{"value_format": "%.2f"}
	)
	_distance = distance_data["slider"].value

	var height_data := module_handle.create_slider(
		"Height", 0.0, 20.0, 0.25, _height,
		Callable(self, "_on_height_changed"),
		{"value_format": "%.2f"}
	)
	_height = height_data["slider"].value

	var pitch_data := module_handle.create_slider(
		"Pitch (deg)", -60.0, 10.0, 1.0, _pitch_deg,
		Callable(self, "_on_pitch_changed"),
		{"value_format": "%.0f"}
	)
	_pitch_deg = pitch_data["slider"].value

	var fov_data := module_handle.create_slider(
		"FOV", 40.0, 100.0, 1.0, _fov,
		Callable(self, "_on_fov_changed"),
		{"value_format": "%.0f"}
	)
	_fov = fov_data["slider"].value

	var copy_button := Button.new()
	copy_button.text = "Copy camera config to clipboard"
	copy_button.pressed.connect(_on_copy_pressed)
	_body.add_child(copy_button)

	var hint := Label.new()
	hint.text = "Paste this text back to Scotty so he can lock in camera values."
	_body.add_child(hint)

func _on_distance_changed(value: float) -> void:
	_distance = value
	_update_camera_transform()

func _on_height_changed(value: float) -> void:
	_height = value
	_update_camera_transform()

func _on_pitch_changed(value: float) -> void:
	_pitch_deg = value
	_update_camera_transform()

func _on_fov_changed(value: float) -> void:
	_fov = value
	_update_camera_transform()

func _update_camera_transform() -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	if _spring != null and is_instance_valid(_spring):
		var spring_xform := _spring.transform
		spring_xform.origin = Vector3(0.0, _height, 0.0)
		_spring.transform = spring_xform
	var cam_xform := _camera.transform
	cam_xform.origin = Vector3(0.0, 0.0, _distance)
	_camera.transform = cam_xform
	_camera.rotation_degrees = Vector3(_pitch_deg, 0.0, 0.0)
	_camera.fov = _fov

func _on_copy_pressed() -> void:
	var txt := "cab87_camera: distance=%.2f height=%.2f pitch=%.1f fov=%.1f" % [_distance, _height, _pitch_deg, _fov]
	if OS.has_feature("web"):
		print("[CAB87_CAMERA] " + txt)
	else:
		DisplayServer.clipboard_set(txt)
	push_warning("Camera config copied: %s" % txt)
