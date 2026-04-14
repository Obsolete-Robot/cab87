extends Node

## Minimal ServiceRegistry stub for cab87
## Only keeps the API surface needed by DebugPanelService.

signal service_registered(service_name: String, service: Node)

var _services: Dictionary = {}

func _ready() -> void:
	# Nothing to auto-discover in this prototype.
	pass

func register_debug_panel_service(service: Node) -> void:
	_register_service('DebugPanelService', service)

func register_service(service_name: String, service: Node) -> void:
	_register_service(service_name, service)

func _register_service(service_name: String, service: Node) -> void:
	if service == null or not is_instance_valid(service):
		return
	_services[service_name] = service
	service_registered.emit(service_name, service)

func get_service(service_name: String) -> Node:
	var service: Node = _services.get(service_name)
	if service == null or not is_instance_valid(service):
		return null
	return service
