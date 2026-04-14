class_name DebugCollapsibleSection
extends VBoxContainer

signal collapsed_changed(section_id: StringName, collapsed: bool)

@export var section_id: StringName = &""
@export var title: String = ""

@onready var _header_button: Button = $HeaderButton
@onready var _body_container: VBoxContainer = $BodyContainer

var _collapsed: bool = false

func _ready() -> void:
	_update_header_text()
	_apply_collapsed_state()
	if _header_button != null:
		_header_button.toggled.connect(_on_header_toggled)

func set_section_id(value: StringName) -> void:
	section_id = value

func set_title(value: String) -> void:
	title = value
	_update_header_text()

func get_body_container() -> VBoxContainer:
	return _body_container

func set_collapsed(collapsed: bool) -> void:
	if _collapsed == collapsed:
		return
	_collapsed = collapsed
	_apply_collapsed_state()
	collapsed_changed.emit(section_id, _collapsed)

func is_collapsed() -> bool:
	return _collapsed

func _on_header_toggled(pressed: bool) -> void:
	set_collapsed(not pressed)

func _apply_collapsed_state() -> void:
	if _body_container != null:
		_body_container.visible = not _collapsed
	if _header_button != null:
		_header_button.button_pressed = not _collapsed
	_update_header_text()

func _update_header_text() -> void:
	if _header_button == null:
		return
	var prefix: String = "-" if not _collapsed else "+"
	var label_text: String = title if title != "" else String(section_id)
	_header_button.text = "%s %s" % [prefix, label_text]
