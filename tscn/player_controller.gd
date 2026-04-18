extends CharacterBody3D

@export var move_speed := 5.5
@export var acceleration := 14.0
@export var gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float

@onready var model_root: Node3D = $ModelRoot

var _animation_player: AnimationPlayer

func _ready() -> void:
	_ensure_input_map()
	_animation_player = _find_animation_player(self)
	_play_idle_if_possible()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction := Vector3(input_vector.x, 0.0, input_vector.y)

	if move_direction.length() > 0.0:
		move_direction = move_direction.normalized()
		var target_velocity := move_direction * move_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
		model_root.rotation.y = lerp_angle(model_root.rotation.y, atan2(velocity.x, velocity.z), 12.0 * delta)
		_play_walk_if_possible()
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		_play_idle_if_possible()

	move_and_slide()

func _ensure_input_map() -> void:
	_add_action_if_missing("move_up", [KEY_W, KEY_UP])
	_add_action_if_missing("move_down", [KEY_S, KEY_DOWN])
	_add_action_if_missing("move_left", [KEY_A, KEY_LEFT])
	_add_action_if_missing("move_right", [KEY_D, KEY_RIGHT])

func _add_action_if_missing(action: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	for keycode in keys:
		var event := InputEventKey.new()
		event.keycode = keycode
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func _play_idle_if_possible() -> void:
	if _animation_player == null:
		return
	if _animation_player.has_animation("idle") and _animation_player.current_animation != "idle":
		_animation_player.play("idle")
	elif _animation_player.current_animation.is_empty():
		var list := _animation_player.get_animation_list()
		if not list.is_empty():
			_animation_player.play(list[0])

func _play_walk_if_possible() -> void:
	if _animation_player == null:
		return
	for name in ["walk", "run", "jog", "locomotion"]:
		if _animation_player.has_animation(name):
			if _animation_player.current_animation != name:
				_animation_player.play(name)
			return

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result != null:
			return result
	return null
