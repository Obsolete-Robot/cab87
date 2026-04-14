extends Node

## Manages debug panel modules. Add as an autoload singleton named "DebugPanelService".
## Modules register themselves here and get wired to the UI automatically.

var _debug_panel_view: DebugPanelView
var _controllers: Dictionary[StringName, DebugPanelModuleController] = {}
var _auto_discover_enabled: bool = true
var _default_module_paths: Array[String] = []

func register_controller(controller: DebugPanelModuleController) -> void:
	if controller == null or not is_instance_valid(controller):
		return
	var module_id: StringName = controller.get_module_id()
	if _controllers.has(module_id):
		var existing: DebugPanelModuleController = _controllers[module_id]
		if is_instance_valid(existing):
			push_warning("DebugPanelService: Module %s already registered" % module_id)
			return
		else:
			_controllers.erase(module_id)
	_controllers[module_id] = controller
	if _debug_panel_view != null:
		_register_module_ui(controller)

func discover_modules_in_scene(root: Node = null) -> void:
	if root == null:
		var tree: SceneTree = get_tree()
		if tree == null or tree.current_scene == null:
			return
		root = tree.current_scene
	_discover_modules_recursive(root)

func _discover_modules_recursive(node: Node) -> void:
	if node is DebugPanelModuleController:
		var controller: DebugPanelModuleController = node as DebugPanelModuleController
		if controller.module_handle == null:
			var module_id: StringName = controller.get_module_id()
			if not _controllers.has(module_id):
				register_controller(controller)
	for child in node.get_children():
		_discover_modules_recursive(child)

func unregister_controller(controller: DebugPanelModuleController) -> void:
	if controller == null:
		return
	var module_id: StringName = controller.get_module_id()
	_controllers.erase(module_id)
	if _debug_panel_view != null:
		var section: DebugCollapsibleSection = _debug_panel_view.get_section(module_id)
		if section != null:
			_debug_panel_view.remove_section(module_id)

func set_debug_panel_view(view: DebugPanelView) -> void:
	_debug_panel_view = view
	if _debug_panel_view != null:
		call_deferred("_setup_modules")

func set_default_module_paths(paths: Array[String]) -> void:
	## Set the list of module script paths to auto-create when no modules are found.
	## Call this before the panel view is set, e.g., in your game's _ready().
	_default_module_paths = paths

func _register_module_ui(controller: DebugPanelModuleController) -> void:
	if _debug_panel_view == null or controller == null:
		return
	if not is_instance_valid(controller):
		return
	if controller.module_handle != null:
		return
	var module_id: StringName = controller.get_module_id()
	var title: String = controller.get_module_title()
	var collapsed: bool = controller.get_default_collapsed()
	var section: DebugCollapsibleSection = _debug_panel_view.create_section(module_id, title, collapsed)
	if section == null:
		push_warning("DebugPanelService: Failed to create section for module %s" % module_id)
		return
	var handle: DebugPanelModuleHandle = DebugPanelModuleHandle.new(module_id, section)
	controller.on_module_registered(handle)

func get_debug_panel_view() -> DebugPanelView:
	return _debug_panel_view

func _setup_modules() -> void:
	if _debug_panel_view == null:
		return
	# Clean up freed controllers
	var controllers_to_remove: Array[StringName] = []
	for module_id in _controllers.keys():
		var controller: DebugPanelModuleController = _controllers[module_id]
		if not is_instance_valid(controller):
			controllers_to_remove.append(module_id)
	for module_id in controllers_to_remove:
		_controllers.erase(module_id)
	# Auto-discover modules in scene
	if _auto_discover_enabled:
		discover_modules_in_scene()
		# If no modules found and defaults are configured, create them
		if _controllers.is_empty() and not _default_module_paths.is_empty():
			var tree: SceneTree = get_tree()
			if tree != null and tree.current_scene != null:
				_create_default_modules(tree.current_scene)
	# Register all valid controllers
	for controller in _controllers.values():
		if is_instance_valid(controller):
			_register_module_ui(controller)

func create_module_from_script(script_path: String, parent: Node = null) -> void:
	var script_resource: GDScript = load(script_path) as GDScript
	if script_resource == null:
		push_warning("DebugPanelService: Failed to load script: %s" % script_path)
		return
	if parent == null:
		var tree: SceneTree = get_tree()
		if tree == null or tree.current_scene == null:
			push_warning("DebugPanelService: No scene available to add module")
			return
		parent = tree.current_scene
	var module_node: Node = Node.new()
	module_node.set_script(script_resource)
	parent.call_deferred("add_child", module_node)

func _create_default_modules(parent: Node) -> void:
	for path in _default_module_paths:
		create_module_from_script(path, parent)

func _exit_tree() -> void:
	var controllers_to_unregister: Array[DebugPanelModuleController] = []
	for controller in _controllers.values():
		if is_instance_valid(controller):
			controllers_to_unregister.append(controller)
	for controller in controllers_to_unregister:
		unregister_controller(controller)
	_controllers.clear()
	_debug_panel_view = null
