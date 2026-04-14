class_name DebugPanelGeneralModule
extends DebugPanelModuleController

var _body: VBoxContainer
var _fps_label: Label
var _drawcalls_label: Label
var _triangles_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	if DebugPanelService != null:
		DebugPanelService.register_controller(self)
	else:
		push_warning("DebugPanelGeneralModule: DebugPanelService not available; module inactive")

func get_module_id() -> StringName:
	return StringName("general")

func get_module_title() -> String:
	return "General"

func on_module_registered(handle: DebugPanelModuleHandle) -> void:
	super.on_module_registered(handle)
	_body = handle.get_body_container()
	_build_ui()

func on_module_unregistered() -> void:
	super.on_module_unregistered()
	_body = null
	set_process(false)

func get_default_collapsed() -> bool:
	return true

func _process(_delta: float) -> void:
	if module_handle == null:
		return
	_update_stats()

func _build_ui() -> void:
	if module_handle == null:
		return
	module_handle.clear()
	_fps_label = _create_label("FPS: --")
	_body.add_child(_fps_label)
	_drawcalls_label = _create_label("Drawcalls: --")
	_body.add_child(_drawcalls_label)
	_triangles_label = _create_label("Triangles: --")
	_body.add_child(_triangles_label)

func _create_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label

func _update_stats() -> void:
	if _fps_label == null or _drawcalls_label == null or _triangles_label == null:
		return
	var fps: float = Engine.get_frames_per_second()
	_fps_label.text = "FPS: %d" % int(fps)
	var drawcalls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	_drawcalls_label.text = "Drawcalls: %d" % drawcalls
	var triangles: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	_triangles_label.text = "Triangles: %d" % triangles

