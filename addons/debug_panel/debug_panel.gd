extends Control

class_name DebugPanelView

@export var collapsible_section_scene: PackedScene

@onready var _toggle_button: Button = %ToggleButton
@onready var _modules_scroll: ScrollContainer = %ModulesScroll
@onready var _modules_container: VBoxContainer = %Modules
@onready var _template_section: DebugCollapsibleSection = %TemplateSection

var _sections: Dictionary[StringName, DebugCollapsibleSection] = {}
var _body_visible: bool = false

func _ready() -> void:
	set_panel_visible(false)
	if _toggle_button != null:
		_toggle_button.toggled.connect(_on_body_toggled)
	set_body_visible(false)
	if _template_section != null:
		_template_section.visible = false
	add_to_group("debug_panel")
	if DebugPanelService != null:
		DebugPanelService.set_debug_panel_view(self)

func create_section(section_id: StringName, title: String, collapsed: bool = false) -> DebugCollapsibleSection:
	if _sections.has(section_id):
		return _sections[section_id]
	var section: DebugCollapsibleSection = _instantiate_section()
	if section == null:
		push_warning("DebugPanelView: Failed to create section %s" % section_id)
		return null
	section.set_section_id(section_id)
	section.set_title(title)
	_modules_container.add_child(section)
	if collapsed:
		section.set_collapsed(true)
	_sections[section_id] = section
	return section

func get_section(section_id: StringName) -> DebugCollapsibleSection:
	if not _sections.has(section_id):
		return null
	return _sections[section_id]

func remove_section(section_id: StringName) -> void:
	if not _sections.has(section_id):
		return
	var section: DebugCollapsibleSection = _sections[section_id]
	if is_instance_valid(section):
		section.queue_free()
	_sections.erase(section_id)

func clear_sections() -> void:
	for section_id in _sections.keys():
		var section: DebugCollapsibleSection = _sections[section_id]
		if is_instance_valid(section):
			section.queue_free()
	_sections.clear()

func toggle_visibility() -> void:
	visible = not visible

func set_panel_visible(desired: bool) -> void:
	if visible == desired:
		return
	visible = desired

func is_panel_visible() -> bool:
	return visible

func set_body_visible(desired: bool) -> void:
	if _body_visible == desired:
		return
	_body_visible = desired
	if _modules_scroll != null:
		_modules_scroll.visible = desired
	if _toggle_button != null:
		_toggle_button.button_pressed = desired
		_toggle_button.text = "Hide" if desired else "Show"

func _on_body_toggled(pressed: bool) -> void:
	set_body_visible(pressed)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos: Vector2 = mouse_event.position
			var panel_rect: Rect2 = get_global_rect()
			if not panel_rect.has_point(mouse_pos):
				_release_focus_if_owned()

func _release_focus_if_owned() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner == null:
		return
	if focus_owner == self or is_ancestor_of(focus_owner):
		focus_owner.release_focus()

func panel_has_focus() -> bool:
	## Returns true if the debug panel or any child control has keyboard focus.
	if not visible:
		return false
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner == null:
		return false
	return focus_owner == self or is_ancestor_of(focus_owner)

func _instantiate_section() -> DebugCollapsibleSection:
	if collapsible_section_scene != null:
		var instantiated := collapsible_section_scene.instantiate()
		if instantiated is DebugCollapsibleSection:
			return instantiated as DebugCollapsibleSection
		if instantiated is Control:
			return null
	if _template_section != null:
		var duplicate := _template_section.duplicate() as Control
		if duplicate is DebugCollapsibleSection:
			return duplicate
	return null
