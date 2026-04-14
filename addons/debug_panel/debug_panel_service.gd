extends Node

var _debug_panel_view: DebugPanelView
var _controllers: Dictionary[StringName, DebugPanelModuleController] = {}
var _auto_discover_enabled: bool = true

func _ready() -> void:
	# Register self with ServiceRegistry
	call_deferred("_register_with_service_registry")

func _register_with_service_registry() -> void:
	if ServiceRegistry != null:
		ServiceRegistry.register_debug_panel_service(self)

func register_controller(controller: DebugPanelModuleController) -> void:
	if controller == null or not is_instance_valid(controller):
		return
	var module_id: StringName = controller.get_module_id()
	if _controllers.has(module_id):
		# Check if existing controller is still valid
		var existing: DebugPanelModuleController = _controllers[module_id]
		if is_instance_valid(existing):
			push_warning("DebugPanelService: Module %s already registered" % module_id)
			return
		else:
			# Existing controller was freed, remove it
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
		# Skip if already registered (has a handle) or already in dictionary
		if controller.module_handle == null:
			var module_id: StringName = controller.get_module_id()
			if not _controllers.has(module_id):
				register_controller(controller)
			# If already in dictionary, skip (already registered or being registered)
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
		# Defer module setup to avoid timing issues during _ready()
		call_deferred("_setup_modules")

func _register_module_ui(controller: DebugPanelModuleController) -> void:
	if _debug_panel_view == null or controller == null:
		return
	# Check if controller is still valid (not freed)
	if not is_instance_valid(controller):
		return
	# Skip if controller already has a handle (already registered)
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
	# Clean up freed controllers first
	var controllers_to_remove: Array[StringName] = []
	for module_id in _controllers.keys():
		var controller: DebugPanelModuleController = _controllers[module_id]
		if not is_instance_valid(controller):
			controllers_to_remove.append(module_id)
	# Remove freed controllers
	for module_id in controllers_to_remove:
		_controllers.erase(module_id)
	# Auto-discover modules in scene if enabled
	if _auto_discover_enabled:
		discover_modules_in_scene()
		# If no default modules found, create default modules
		# Check specifically for default module IDs, not just any modules
		var has_default_modules: bool = _has_any_default_module()
		if not has_default_modules:
			var tree: SceneTree = get_tree()
			if tree != null and tree.current_scene != null:
				create_default_modules(tree.current_scene)
	# Register all existing controllers (only valid ones)
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
	# Use deferred call to avoid timing issues during _ready()
	# The module will register itself in its _ready() callback
	parent.call_deferred("add_child", module_node)

func create_default_modules(parent: Node = null) -> void:
	var module_paths: Array[String] = [
		"res://addons/debug_panel/modules/debug_panel_core_module.gd",
		"res://addons/debug_panel/modules/debug_panel_camera_module.gd"
	]
	
	for path in module_paths:
		create_module_from_script(path, parent)

func _has_any_default_module() -> bool:
	# List of default module IDs for cab87
	var default_module_ids: Array[StringName] = [
		StringName("core"),
		StringName("camera")
	]
	
	# Check if any default module is already registered
	for module_id in default_module_ids:
		if _controllers.has(module_id):
			return true
	return false

func _exit_tree() -> void:
	## Clean up all controllers and references when service is removed from tree.
	# Unregister all controllers
	var controllers_to_unregister: Array[DebugPanelModuleController] = []
	for controller in _controllers.values():
		if is_instance_valid(controller):
			controllers_to_unregister.append(controller)
	
	for controller in controllers_to_unregister:
		unregister_controller(controller)
	
	# Clear all dictionaries
	_controllers.clear()
	_debug_panel_view = null

