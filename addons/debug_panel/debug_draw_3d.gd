extends Node3D
class_name DebugDraw3D

## Simple 3D debug drawing utility using ImmediateMesh
## Draws lines, shapes, and text in 3D space for debugging

var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _material: StandardMaterial3D

func _ready() -> void:
	# Create mesh instance for drawing
	_immediate_mesh = ImmediateMesh.new()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_immediate_mesh.surface_end()
	
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _immediate_mesh
	add_child(_mesh_instance)
	
	# Create unshaded material for debug lines
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.no_depth_test = false
	_mesh_instance.material_override = _material
	
	# Set to always visible
	visible = true

func draw_line(from: Vector3, to: Vector3, color: Color = Color.WHITE) -> void:
	## Draw a line from one point to another
	if _immediate_mesh == null:
		return
	
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(from)
	_immediate_mesh.surface_add_vertex(to)
	_immediate_mesh.surface_end()

func clear() -> void:
	## Clear all drawn lines
	if _immediate_mesh == null:
		return
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_immediate_mesh.surface_end()

func set_enabled(enabled: bool) -> void:
	## Enable or disable debug drawing
	visible = enabled

