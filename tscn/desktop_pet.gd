extends Node3D

@onready var pet_container: Node3D = $PetContainer

var _dragging := false
var _drag_offset := Vector2i.ZERO

func _ready() -> void:
	_setup_window()
	_play_first_animation()

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	pet_container.position.y = -0.95 + sin(t * 2.2) * 0.08
	pet_container.rotation.y = sin(t * 0.8) * 0.2
	pet_container.rotation.z = sin(t * 1.7) * 0.03

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_drag_offset = DisplayServer.mouse_get_position() - get_window().position

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
