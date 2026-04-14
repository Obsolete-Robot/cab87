extends CharacterBody3D

@export var acceleration: float = 40.0
@export var max_speed: float = 60.0
@export var brake_force: float = 60.0
@export var reverse_max_speed: float = 20.0
@export var steering_speed: float = 2.8
@export var drag: float = 4.0
@export var drift_friction: float = 6.0
@export var handbrake_drift_friction: float = 2.0
@export var min_steer_speed: float = 5.0

var _target_speed: float = 0.0

func _ready() -> void:
	_ensure_input_actions()

func _physics_process(delta: float) -> void:
	var forward_input := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	var steer_input := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	var handbrake := Input.is_action_pressed("handbrake")

	_apply_engine_force(forward_input, delta)
	_apply_steering(steer_input, delta)
	_apply_drift_and_friction(handbrake, delta)

	velocity.y = 0.0
	move_and_slide()

	if Input.is_action_just_pressed("reset_car"):
		_reset_to_origin()

func _apply_engine_force(input: float, delta: float) -> void:
	if input > 0.0:
		_target_speed = min(_target_speed + acceleration * delta, max_speed)
	elif input < 0.0:
		_target_speed = max(_target_speed - brake_force * delta, -reverse_max_speed)
	else:
		_target_speed = lerp(_target_speed, 0.0, drag * delta)

	var forward_dir: Vector3 = -transform.basis.z
	var desired_velocity: Vector3 = forward_dir * _target_speed

	var local_velocity: Vector3 = transform.basis.inverse() * velocity
	var desired_local: Vector3 = transform.basis.inverse() * desired_velocity

	# Strong alignment on forward axis, looser on lateral for sliding
	var forward_lerp: float = float(clamp(drag * 2.0 * delta, 0.0, 1.0))
	var lateral_lerp: float = float(clamp(drag * 0.8 * delta, 0.0, 1.0))

	local_velocity.z = lerp(local_velocity.z, desired_local.z, forward_lerp)
	local_velocity.x = lerp(local_velocity.x, desired_local.x, lateral_lerp)

	velocity = transform.basis * local_velocity

func _apply_steering(input: float, delta: float) -> void:
	var speed: float = velocity.length()
	if speed < min_steer_speed:
		return

	var direction: float = 1.0
	if _target_speed < 0.0:
		direction = -1.0
	var steer_amount: float = steering_speed * input * delta * float(clamp(speed / max_speed, 0.25, 1.0))
	rotate_y(steer_amount * direction)

func _apply_drift_and_friction(handbrake: bool, delta: float) -> void:
	var local_velocity: Vector3 = transform.basis.inverse() * velocity
	var friction: float = handbrake_drift_friction if handbrake else drift_friction
	local_velocity.x = lerp(local_velocity.x, 0.0, clamp(friction * delta, 0.0, 1.0))
	velocity = transform.basis * local_velocity

func _reset_to_origin() -> void:
	global_transform.origin = Vector3.ZERO
	velocity = Vector3.ZERO
	_target_speed = 0.0

func _ensure_input_actions() -> void:
	_ensure_action("accelerate", [KEY_W, KEY_UP])
	_ensure_action("brake", [KEY_S, KEY_DOWN])
	_ensure_action("steer_left", [KEY_A, KEY_LEFT])
	_ensure_action("steer_right", [KEY_D, KEY_RIGHT])
	_ensure_action("handbrake", [KEY_SPACE])
	_ensure_action("reset_car", [KEY_R])

func _ensure_action(name: StringName, keys: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	if InputMap.action_get_events(name).is_empty():
		for code in keys:
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			InputMap.action_add_event(name, ev)
