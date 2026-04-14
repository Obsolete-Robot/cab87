extends Node3D

@export var city_size_x: int = 10
@export var city_size_z: int = 10
@export var block_size: float = 40.0
@export var road_width: float = 12.0
@export var building_min_height: float = 4.0
@export var building_max_height: float = 24.0
@export var seed: int = 1

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = seed
	_generate_city()

func regenerate_with_new_seed() -> void:
	seed = randi()
	_rng.seed = seed
	_generate_city()

func _generate_city() -> void:
	for child in get_children():
		child.queue_free()

	for x in range(city_size_x):
		for z in range(city_size_z):
			var block_origin := Vector3(
				(x - city_size_x / 2.0) * block_size,
				0.0,
				(z - city_size_z / 2.0) * block_size
			)
			_create_block(block_origin)

func _create_block(origin: Vector3) -> void:
	# Road slab
	var road := MeshInstance3D.new()
	var road_mesh := BoxMesh.new()
	road_mesh.size = Vector3(block_size, 0.2, block_size)
	road.mesh = road_mesh
	road.position = origin + Vector3(0.0, -0.1, 0.0)

	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.08, 0.08, 0.1)
	road_mat.roughness = 0.9
	road.material_override = road_mat

	add_child(road)

	# Simple buildings pushed toward the edges so the center stays driveable
	var building_count := _rng.randi_range(3, 7)
	for i in range(building_count):
		var building := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var w := _rng.randf_range(3.0, 6.0)
		var d := _rng.randf_range(3.0, 6.0)
		var h := _rng.randf_range(building_min_height, building_max_height)
		mesh.size = Vector3(w, h, d)
		building.mesh = mesh

		var offset := Vector3(
			_rng.randf_range(-block_size * 0.5 + w, block_size * 0.5 - w),
			h * 0.5,
			_rng.randf_range(-block_size * 0.5 + d, block_size * 0.5 - d)
		)

		if abs(offset.x) < road_width * 0.5:
			offset.x = sign(offset.x) * road_width * 0.5
		if abs(offset.z) < road_width * 0.5:
			offset.z = sign(offset.z) * road_width * 0.5

		building.position = origin + offset

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.from_hsv(_rng.randf(), 0.45, _rng.randf_range(0.4, 0.9))
		mat.metallic = 0.05
		mat.roughness = 0.75
		building.material_override = mat

		add_child(building)
