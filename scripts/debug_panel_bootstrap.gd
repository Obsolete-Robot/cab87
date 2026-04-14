extends Node

func _ready() -> void:
	if DebugPanelService != null:
		DebugPanelService.set_default_module_paths([
			"res://addons/debug_panel/modules/debug_panel_general_module.gd",
			"res://addons/debug_panel/modules/debug_panel_camera_module.gd"
		])
