extends Node3D

@export var camera_follow_speed := 6.0
@export var camera_offset := Vector3(0, 0, 0)

@onready var player: CharacterBody3D = $Player
@onready var camera_rig: Node3D = $CameraRig

func _ready() -> void:
	camera_rig.global_position = player.global_position + camera_offset

func _process(delta: float) -> void:
	var target := player.global_position + camera_offset
	camera_rig.global_position = camera_rig.global_position.lerp(target, clamp(camera_follow_speed * delta, 0.0, 1.0))
