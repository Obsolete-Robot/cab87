class_name DebugPanelModuleController
extends Node

var module_handle: DebugPanelModuleHandle

func get_module_id() -> StringName:
	return &""

func get_module_title() -> String:
	return ""

func get_default_collapsed() -> bool:
	return false

func on_module_registered(handle: DebugPanelModuleHandle) -> void:
	module_handle = handle

func on_module_unregistered() -> void:
	module_handle = null
