class_name DebugPanelModuleHandle
extends RefCounted

var module_id: StringName
var section: DebugCollapsibleSection
var _body_container: VBoxContainer

func _init(module_id_value: StringName, section_value: DebugCollapsibleSection) -> void:
	module_id = module_id_value
	section = section_value
	_body_container = section_value.get_body_container()

func get_body_container() -> VBoxContainer:
	return _body_container

func add_control(control: Control) -> void:
	if control == null:
		return
	_body_container.add_child(control)

func clear() -> void:
	for child in _body_container.get_children():
		if is_instance_valid(child):
			child.queue_free()

func set_collapsed(collapsed: bool) -> void:
	if section == null:
		return
	section.set_collapsed(collapsed)

func is_collapsed() -> bool:
	if section == null:
		return false
	return section.is_collapsed()

func create_slider(
		label_text: String,
		min_value: float,
		max_value: float,
		step: float,
		initial_value: float,
		on_value_changed: Callable,
		options: Dictionary = {}
	) -> Dictionary:
	var separation: int = int(options.get("separation", 6))
	var allow_lesser: bool = bool(options.get("allow_lesser", false))
	var allow_greater: bool = bool(options.get("allow_greater", false))
	var value_format: String = String(options.get("value_format", "%.2f"))
	var formatter_variant: Variant = options.get("value_formatter", null)
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", separation)
	_body_container.add_child(container)

	var name_label := Label.new()
	name_label.text = label_text
	container.add_child(name_label)

	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.allow_lesser = allow_lesser
	slider.allow_greater = allow_greater
	slider.value = initial_value
	container.add_child(slider)

	var value_label := Label.new()
	if formatter_variant is Callable and (formatter_variant as Callable).is_valid():
		var formatter_callable: Callable = formatter_variant as Callable
		value_label.text = formatter_callable.call(initial_value)
		var update_callable := func(value: float) -> void:
			value_label.text = formatter_callable.call(value)
		slider.value_changed.connect(update_callable)
	else:
		value_label.text = value_format % initial_value
		var update_callable := func(value: float) -> void:
			value_label.text = value_format % value
		slider.value_changed.connect(update_callable)
	container.add_child(value_label)

	if on_value_changed.is_valid():
		slider.value_changed.connect(on_value_changed)

	return {
		"container": container,
		"label": name_label,
		"slider": slider,
		"value_label": value_label
	}
