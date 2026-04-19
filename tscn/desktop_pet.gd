extends Node3D

@export var bob_base_height := -0.95
@export var bob_amplitude := 0.08
@export var bob_speed := 2.2
@export var sway_speed := 0.8
@export var tilt_speed := 1.7
@export var drag_follow_lerp := 16.0

@onready var pet_container: Node3D = $PetContainer

var _dragging := false
var _drag_offset := Vector2i.ZERO
var _target_scale := Vector3.ONE
var _pulse_timer := 0.0

func _ready() -> void:
	_setup_window()
	_play_first_animation()

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var current_drag_boost := 0.03 if _dragging else 0.0
	pet_container.position.y = bob_base_height + sin(t * bob_speed) * (bob_amplitude + current_drag_boost)
	pet_container.rotation.y = sin(t * sway_speed) * 0.2
	pet_container.rotation.z = sin(t * tilt_speed) * (0.03 + current_drag_boost)

	if _pulse_timer > 0.0:
		_pulse_timer = max(_pulse_timer - delta, 0.0)
		var pulse := 1.0 + sin((0.2 - _pulse_timer) * 30.0) * 0.05
		_target_scale = Vector3.ONE * pulse
	elif not _dragging:
		_target_scale = Vector3.ONE

	pet_container.scale = pet_container.scale.lerp(_target_scale, clamp(drag_follow_lerp * delta, 0.0, 1.0))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if _dragging:
				_drag_offset = DisplayServer.mouse_get_position() - get_window().position
				if event.double_click:
					_pulse_timer = 0.2
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			get_tree().quit()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_target_scale = (_target_scale * 1.08).clamp(Vector3.ONE * 0.7, Vector3.ONE * 1.5)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_target_scale = (_target_scale * 0.92).clamp(Vector3.ONE * 0.7, Vector3.ONE * 1.5)

	if event is InputEventMouseMotion and _dragging:
		get_window().position = DisplayServer.mouse_get_position() - _drag_offset

func _setup_window() -> void:
	var window := get_window()
	window.borderless = true
	window.always_on_top = true
	window.transparent_bg = true

func _play_first_animation() -> void:
	var animation_player := _find_animation_player(self)
	if animation_player == null:
		push_warning("No AnimationPlayer found in imported pet resource.")
		return

	if animation_player.has_animation("idle"):
		animation_player.play("idle")
		return

	var animation_names := animation_player.get_animation_list()
	if animation_names.is_empty():
		push_warning("AnimationPlayer exists but contains no animations.")
		return

	animation_player.play(animation_names[0])

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node

	for child in node.get_children():
		var result := _find_animation_player(child)
		if result != null:
			return result

	return null
