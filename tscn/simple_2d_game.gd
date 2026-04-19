extends Node2D

@export var player_speed := 320.0
@export var enemy_base_speed := 120.0
@export var enemy_spawn_interval := 1.2

@onready var score_label: Label = $CanvasLayer/UI/ScoreLabel
@onready var hint_label: Label = $CanvasLayer/UI/HintLabel

var player_pos := Vector2.ZERO
var player_radius := 16.0
var coin_pos := Vector2.ZERO
var coin_radius := 10.0
var score := 0
var game_over := false

var spawn_timer := 0.0
var enemies: Array[Dictionary] = []

func _ready() -> void:
	randomize()
	_reset_game()

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			_reset_game()
		queue_redraw()
		return

	_update_player(delta)
	_spawn_and_update_enemies(delta)
	_check_collisions()
	_update_ui()
	queue_redraw()

func _draw() -> void:
	var rect := get_viewport_rect()
	draw_rect(Rect2(Vector2.ZERO, rect.size), Color("1e1f29"), true)

	# coin
	draw_circle(coin_pos, coin_radius, Color("ffd166"))

	# player
	draw_circle(player_pos, player_radius, Color("4cc9f0"))

	# enemies
	for enemy in enemies:
		draw_circle(enemy["pos"], enemy["radius"], Color("ef476f"))

func _update_player(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	player_pos += dir * player_speed * delta
	player_pos = player_pos.clamp(Vector2(player_radius, player_radius), get_viewport_rect().size - Vector2(player_radius, player_radius))

func _spawn_and_update_enemies(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= enemy_spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy()

	for enemy in enemies:
		enemy["pos"] += enemy["vel"] * delta
		var pos: Vector2 = enemy["pos"]
		var vel: Vector2 = enemy["vel"]
		var r: float = enemy["radius"]
		var size := get_viewport_rect().size
		if pos.x <= r or pos.x >= size.x - r:
			vel.x *= -1.0
		if pos.y <= r or pos.y >= size.y - r:
			vel.y *= -1.0
		enemy["vel"] = vel
		enemy["pos"] = pos.clamp(Vector2(r, r), size - Vector2(r, r))

func _spawn_enemy() -> void:
	var size := get_viewport_rect().size
	var pos := Vector2(randf_range(20, size.x - 20), randf_range(20, size.y - 20))
	var dir := Vector2.RIGHT.rotated(randf() * TAU)
	var speed := enemy_base_speed + score * 6.0
	enemies.append({"pos": pos, "vel": dir * speed, "radius": 14.0})

func _check_collisions() -> void:
	# coin pickup
	if player_pos.distance_to(coin_pos) <= player_radius + coin_radius:
		score += 1
		coin_pos = _random_position(coin_radius)
		enemy_spawn_interval = max(0.4, 1.2 - score * 0.03)

	# enemy hit
	for enemy in enemies:
		if player_pos.distance_to(enemy["pos"]) <= player_radius + enemy["radius"]:
			game_over = true
			hint_label.text = "游戏结束！按 Enter 重开"
			return

func _random_position(radius: float) -> Vector2:
	var size := get_viewport_rect().size
	return Vector2(randf_range(radius, size.x - radius), randf_range(radius, size.y - radius))

func _reset_game() -> void:
	score = 0
	game_over = false
	enemy_spawn_interval = 1.2
	spawn_timer = 0.0
	enemies.clear()
	player_pos = _random_position(player_radius)
	coin_pos = _random_position(coin_radius)
	for i in 3:
		_spawn_enemy()
	hint_label.text = "方向键移动，吃金币躲敌人"
	_update_ui()

func _update_ui() -> void:
	score_label.text = "分数: %d" % score
