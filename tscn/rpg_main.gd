extends Control

const PROFESSIONS := ["牧师", "刺客", "战士", "肉盾", "射手", "法师"]
const TALENTS := ["灼烧", "中毒", "冰冻", "召唤", "月蚀", "圣光"]
const TALENT_COUNTER := {"圣光": "月蚀", "月蚀": "召唤", "召唤": "冰冻", "冰冻": "灼烧", "灼烧": "中毒", "中毒": "圣光"}

const MAX_DEPLOY := 4
const GRID_SIZE := 9
const EXP_PER_LEVEL := 100

const PROFESSION_SKILLS := {
	"牧师": [{"name": "治疗祷言", "power": 24, "target": "ally", "kind": "heal"}, {"name": "圣言冲击", "power": 18, "target": "enemy", "kind": "damage"}],
	"刺客": [{"name": "背刺", "power": 28, "target": "enemy", "kind": "damage"}, {"name": "毒刃连击", "power": 20, "target": "enemy", "kind": "damage", "apply_status": "中毒"}],
	"战士": [{"name": "破甲斩", "power": 24, "target": "enemy", "kind": "damage"}, {"name": "战吼", "power": 0, "target": "self", "kind": "buff", "buff_attack": 0.25}],
	"肉盾": [{"name": "盾击", "power": 18, "target": "enemy", "kind": "damage", "apply_status": "冰冻"}, {"name": "守护姿态", "power": 0, "target": "self", "kind": "buff", "buff_defense": 0.3}],
	"射手": [{"name": "穿云箭", "power": 23, "target": "enemy", "kind": "damage"}, {"name": "连珠射击", "power": 18, "target": "enemy", "kind": "damage", "hits": 2}],
	"法师": [{"name": "奥术飞弹", "power": 22, "target": "enemy", "kind": "damage"}, {"name": "陨火术", "power": 25, "target": "enemy", "kind": "damage", "apply_status": "灼烧"}]
}

const TALENT_SKILLS := {
	"灼烧": {"name": "灼炎印记", "power": 20, "target": "enemy", "kind": "damage", "apply_status": "灼烧"},
	"中毒": {"name": "毒雾侵蚀", "power": 18, "target": "enemy", "kind": "damage", "apply_status": "中毒"},
	"冰冻": {"name": "寒霜禁锢", "power": 16, "target": "enemy", "kind": "damage", "apply_status": "冰冻"},
	"召唤": {"name": "召唤协战", "power": 20, "target": "enemy", "kind": "damage", "summon_bonus": true},
	"月蚀": {"name": "月蚀冲击", "power": 23, "target": "enemy", "kind": "damage", "debuff_attack": 0.2},
	"圣光": {"name": "圣光庇护", "power": 20, "target": "ally", "kind": "heal", "cleanse": true}
}

const BASIC_ATTACK := {"name": "普通攻击", "power": 15, "target": "enemy", "kind": "damage"}

@onready var stage_label: Label = $Root/Margin/VBox/TopBar/StageLabel
@onready var mode_label: Label = $Root/Margin/VBox/TopBar/ModeLabel
@onready var roster_list: ItemList = $Root/Margin/VBox/Body/FormationPanel/RosterList
@onready var hero_info: RichTextLabel = $Root/Margin/VBox/Body/FormationPanel/HeroInfo
@onready var formation_info: Label = $Root/Margin/VBox/Body/FormationPanel/FormationInfo
@onready var battle_button: Button = $Root/Margin/VBox/Body/FormationPanel/StartBattleButton
@onready var reset_button: Button = $Root/Margin/VBox/Body/FormationPanel/ResetFormationButton
@onready var grid: GridContainer = $Root/Margin/VBox/Body/FormationPanel/FormationGrid

@onready var ally_list: ItemList = $Root/Margin/VBox/Body/BattlePanel/AllyList
@onready var enemy_list: ItemList = $Root/Margin/VBox/Body/BattlePanel/EnemyList
@onready var skill_buttons: Array[Button] = [$Root/Margin/VBox/Body/BattlePanel/SkillRow/Skill1, $Root/Margin/VBox/Body/BattlePanel/SkillRow/Skill2, $Root/Margin/VBox/Body/BattlePanel/SkillRow/Skill3, $Root/Margin/VBox/Body/BattlePanel/SkillRow/Skill4]
@onready var battle_log: RichTextLabel = $Root/Margin/VBox/Body/BattlePanel/BattleLog
@onready var battle_hint: Label = $Root/Margin/VBox/Body/BattlePanel/BattleHint
@onready var next_turn_button: Button = $Root/Margin/VBox/Body/BattlePanel/NextTurnButton

var heroes: Array[Dictionary] = []
var formation_slots: Array = []
var floor: int = 1
var pending_boss_reform := false

var battle_active := false
var allies: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var turn_queue: Array[Dictionary] = []
var active_unit: Dictionary = {}
var selected_skill: Dictionary = {}

func _ready() -> void:
	randomize()
	_init_roster()
	_init_formation_grid()
	_connect_ui()
	_refresh_all_ui()

func _init_roster() -> void:
	var id := 1
	for profession in PROFESSIONS:
		for talent in TALENTS:
			heroes.append(_create_hero(id, profession, talent))
			id += 1

func _create_hero(id: int, profession: String, talent: String) -> Dictionary:
	var base_stats: Dictionary = {
		"牧师": {"hp": 120, "atk": 18, "def": 10, "spd": 12},
		"刺客": {"hp": 95, "atk": 26, "def": 8, "spd": 18},
		"战士": {"hp": 130, "atk": 22, "def": 12, "spd": 13},
		"肉盾": {"hp": 180, "atk": 15, "def": 18, "spd": 8},
		"射手": {"hp": 105, "atk": 24, "def": 9, "spd": 16},
		"法师": {"hp": 100, "atk": 25, "def": 8, "spd": 14}
	}
	var stats: Dictionary = base_stats[profession]
	return {
		"id": id,
		"name": "%s-%s-%02d" % [profession, talent, id],
		"profession": profession,
		"talent": talent,
		"level": 1,
		"exp": 0,
		"max_hp": stats["hp"],
		"hp": stats["hp"],
		"atk": stats["atk"],
		"def": stats["def"],
		"spd": stats["spd"],
		"status": {},
		"buff_attack": 0.0,
		"buff_defense": 0.0,
		"skills": _build_skills(profession, talent)
	}

func _build_skills(profession: String, talent: String) -> Array:
	return [BASIC_ATTACK.duplicate(true), PROFESSION_SKILLS[profession][0].duplicate(true), PROFESSION_SKILLS[profession][1].duplicate(true), TALENT_SKILLS[talent].duplicate(true)]

func _init_formation_grid() -> void:
	formation_slots.resize(GRID_SIZE)
	for i in GRID_SIZE:
		formation_slots[i] = null
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(88, 56)
		btn.text = "空位"
		btn.pressed.connect(_on_grid_pressed.bind(i))
		grid.add_child(btn)

func _connect_ui() -> void:
	roster_list.item_selected.connect(_on_roster_selected)
	ally_list.item_selected.connect(_on_target_selected.bind("ally"))
	enemy_list.item_selected.connect(_on_target_selected.bind("enemy"))
	battle_button.pressed.connect(_start_battle)
	reset_button.pressed.connect(_reset_formation)
	next_turn_button.pressed.connect(_force_next_turn)
	for i in skill_buttons.size():
		skill_buttons[i].pressed.connect(_on_skill_pressed.bind(i))

func _refresh_all_ui() -> void:
	_refresh_stage_mode()
	_refresh_roster()
	_refresh_formation_grid()
	_refresh_battle_lists()
	_refresh_skill_buttons()

func _refresh_stage_mode() -> void:
	stage_label.text = "层数: %d%s" % [floor, " (Boss)" if floor % 5 == 0 else ""]
	mode_label.text = "阶段: %s" % ("战斗中" if battle_active else "编队中")
	formation_info.text = "已上阵: %d / %d（3x3站位）" % [_deployed_count(), MAX_DEPLOY]

func _refresh_roster() -> void:
	roster_list.clear()
	for hero in heroes:
		roster_list.add_item(_hero_brief(hero))

func _refresh_formation_grid() -> void:
	for i in grid.get_child_count():
		var btn := grid.get_child(i) as Button
		var hero = formation_slots[i]
		btn.text = "空位" if hero == null else "%s\nLv%d" % [hero["name"], hero["level"]]

func _refresh_battle_lists() -> void:
	ally_list.clear()
	enemy_list.clear()
	for unit in allies:
		ally_list.add_item(_battle_unit_text(unit))
	for unit in enemies:
		enemy_list.add_item(_battle_unit_text(unit))

func _refresh_skill_buttons() -> void:
	for btn in skill_buttons:
		btn.disabled = true
		btn.text = "技能"
	if active_unit.is_empty() or not bool(active_unit.get("is_player", false)):
		battle_hint.text = "等待玩家回合..."
		return
	var skills: Array = active_unit["skills"]
	for i in min(4, skills.size()):
		var skill: Dictionary = skills[i]
		skill_buttons[i].text = skill["name"]
		skill_buttons[i].disabled = false
	battle_hint.text = "请选择技能，再点目标（敌方/我方）"

func _on_roster_selected(index: int) -> void:
	hero_info.text = _hero_detail(heroes[index])

func _on_grid_pressed(slot_index: int) -> void:
	if battle_active:
		return
	if formation_slots[slot_index] != null:
		formation_slots[slot_index] = null
		_refresh_formation_grid()
		_refresh_stage_mode()
		return
	if roster_list.get_selected_items().is_empty():
		battle_log.append_text("\n[编队] 先在左侧点一个角色。")
		return
	if _deployed_count() >= MAX_DEPLOY:
		battle_log.append_text("\n[编队] 最多上阵4名角色。")
		return
	var hero: Dictionary = heroes[roster_list.get_selected_items()[0]]
	if _is_hero_deployed(hero["id"]):
		battle_log.append_text("\n[编队] 该角色已在阵中。")
		return
	formation_slots[slot_index] = hero
	_refresh_formation_grid()
	_refresh_stage_mode()

func _reset_formation() -> void:
	if battle_active:
		return
	for i in GRID_SIZE:
		formation_slots[i] = null
	_refresh_formation_grid()
	_refresh_stage_mode()

func _deployed_count() -> int:
	var count := 0
	for hero in formation_slots:
		if hero != null:
			count += 1
	return count

func _is_hero_deployed(hero_id: int) -> bool:
	for hero in formation_slots:
		if hero != null and hero["id"] == hero_id:
			return true
	return false

func _start_battle() -> void:
	if battle_active:
		return
	if _deployed_count() == 0:
		battle_log.append_text("\n[系统] 请先上阵至少1位角色。")
		return
	if pending_boss_reform:
		_restore_team_status()
		pending_boss_reform = false
		battle_log.append_text("\n[系统] Boss关前重整完毕，队伍状态已恢复。")
	allies.clear()
	enemies.clear()
	for hero in formation_slots:
		if hero != null:
			allies.append(_clone_for_battle(hero, true))
	enemies = _generate_floor_enemies(floor)
	battle_active = true
	turn_queue.clear()
	active_unit.clear()
	selected_skill.clear()
	battle_log.append_text("\n========== 进入第%d层 ==========" % floor)
	_refresh_all_ui()
	_next_turn()

func _generate_floor_enemies(current_floor: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count: int = 2 + min(2, int(current_floor / 3))
	if current_floor % 5 == 0:
		count = 1
	for i in count:
		var profession: String = PROFESSIONS[(current_floor + i) % PROFESSIONS.size()]
		var talent: String = TALENTS[(current_floor + i * 2) % TALENTS.size()]
		var unit := _create_hero(9000 + current_floor * 10 + i, profession, talent)
		unit["name"] = "敌-%s-%s" % [profession, talent]
		var scale := 1.0 + current_floor * 0.14
		if current_floor % 5 == 0:
			scale += 0.8
			unit["name"] = "Boss-%s-%s" % [profession, talent]
		unit["max_hp"] = int(unit["max_hp"] * scale)
		unit["hp"] = unit["max_hp"]
		unit["atk"] = int(unit["atk"] * scale)
		unit["def"] = int(unit["def"] * (0.9 + current_floor * 0.05))
		unit["spd"] = int(unit["spd"] * (0.95 + current_floor * 0.03))
		result.append(_clone_for_battle(unit, false))
	return result

func _clone_for_battle(source: Dictionary, is_player: bool) -> Dictionary:
	var copied := source.duplicate(true)
	copied["is_player"] = is_player
	copied["status"] = {}
	copied["buff_attack"] = 0.0
	copied["buff_defense"] = 0.0
	return copied

func _next_turn() -> void:
	if not battle_active:
		return
	_apply_status_damage()
	_cleanup_dead()
	if _check_battle_end():
		return
	if turn_queue.is_empty():
		turn_queue = allies + enemies
		turn_queue = turn_queue.filter(func(u: Dictionary): return u["hp"] > 0)
		turn_queue.sort_custom(func(a: Dictionary, b: Dictionary): return a["spd"] > b["spd"])
	active_unit = turn_queue.pop_front()
	if active_unit["hp"] <= 0:
		_next_turn()
		return
	var status: Dictionary = active_unit["status"]
	if status.has("冰冻"):
		battle_log.append_text("\n%s 被冰冻，跳过行动。" % active_unit["name"])
		status.erase("冰冻")
		_refresh_battle_lists()
		_next_turn()
		return
	if active_unit["is_player"]:
		battle_hint.text = "轮到 %s，先点技能再点目标。" % active_unit["name"]
		_refresh_skill_buttons()
	else:
		_enemy_act()

func _force_next_turn() -> void:
	if not battle_active:
		return
	if not active_unit.is_empty() and active_unit["is_player"]:
		battle_log.append_text("\n[系统] 已跳过 %s 的行动。" % active_unit["name"])
	_next_turn()

func _on_skill_pressed(index: int) -> void:
	if not battle_active or active_unit.is_empty() or not active_unit["is_player"]:
		return
	var skills: Array = active_unit["skills"]
	if index >= skills.size():
		return
	selected_skill = skills[index]
	battle_hint.text = "已选择 %s，请点%s目标。" % [selected_skill["name"], "敌方" if selected_skill["target"] == "enemy" else "我方"]

func _on_target_selected(target_type: String, index: int) -> void:
	if not battle_active or active_unit.is_empty() or not active_unit["is_player"]:
		return
	if selected_skill.is_empty():
		battle_hint.text = "请先选择技能。"
		return
	if selected_skill["target"] != target_type and selected_skill["target"] != "self":
		battle_hint.text = "该技能目标不匹配。"
		return
	var target: Dictionary
	if selected_skill["target"] == "self":
		target = active_unit
	elif target_type == "enemy":
		target = enemies[index]
	else:
		target = allies[index]
	if target["hp"] <= 0:
		battle_hint.text = "目标已倒下。"
		return
	_execute_skill(active_unit, target, selected_skill)
	selected_skill.clear()
	_refresh_battle_lists()
	_refresh_skill_buttons()
	if _check_battle_end():
		return
	_next_turn()

func _enemy_act() -> void:
	var skill: Dictionary = active_unit["skills"][0]
	for candidate in active_unit["skills"]:
		if candidate["kind"] == "damage":
			skill = candidate
			break
	var targets: Array = allies if skill["target"] == "enemy" else enemies
	targets = targets.filter(func(u: Dictionary): return u["hp"] > 0)
	if targets.is_empty():
		_next_turn()
		return
	var target: Dictionary = targets[randi() % targets.size()]
	_execute_skill(active_unit, target, skill)
	_refresh_battle_lists()
	if _check_battle_end():
		return
	_next_turn()

func _execute_skill(caster: Dictionary, target: Dictionary, skill: Dictionary) -> void:
	var hits := int(skill.get("hits", 1))
	for _i in hits:
		if skill["kind"] == "heal":
			var heal_value := int(skill["power"] + caster["atk"] * 0.5)
			target["hp"] = min(target["max_hp"], target["hp"] + heal_value)
			battle_log.append_text("\n%s 对 %s 施放 %s，恢复 %d HP" % [caster["name"], target["name"], skill["name"], heal_value])
		else:
			var damage := _calc_damage(caster, target, skill)
			target["hp"] = max(0, target["hp"] - damage)
			battle_log.append_text("\n%s 对 %s 施放 %s，造成 %d 伤害" % [caster["name"], target["name"], skill["name"], damage])
	if String(skill.get("apply_status", "")) != "" and target["hp"] > 0:
		var status_name: String = skill["apply_status"]
		target["status"][status_name] = 2
		battle_log.append_text("（附加%s）" % status_name)
	if float(skill.get("buff_attack", 0.0)) > 0.0:
		caster["buff_attack"] += float(skill["buff_attack"])
	if float(skill.get("buff_defense", 0.0)) > 0.0:
		caster["buff_defense"] += float(skill["buff_defense"])
	if float(skill.get("debuff_attack", 0.0)) > 0.0:
		target["buff_attack"] -= float(skill["debuff_attack"])
	if bool(skill.get("summon_bonus", false)):
		var summon_hit := int(caster["atk"] * 0.5)
		target["hp"] = max(0, target["hp"] - summon_hit)
		battle_log.append_text("\n召唤物追击 %s，造成 %d 额外伤害" % [target["name"], summon_hit])
	if bool(skill.get("cleanse", false)):
		target["status"].clear()

func _calc_damage(caster: Dictionary, target: Dictionary, skill: Dictionary) -> int:
	var attack: float = float(caster["atk"]) * (1.0 + float(caster["buff_attack"]))
	var defense: float = float(target["def"]) * (1.0 + float(target["buff_defense"]))
	var damage := int(max(1.0, float(skill["power"]) + attack - defense * 0.7))
	if TALENT_COUNTER[caster["talent"]] == target["talent"]:
		damage = int(damage * 1.35)
		battle_log.append_text(" [克制加成]")
	return damage

func _apply_status_damage() -> void:
	for group in [allies, enemies]:
		for unit in group:
			if unit["hp"] <= 0:
				continue
			var status_keys: Array = unit["status"].keys()
			for status in status_keys:
				if status == "灼烧":
					unit["hp"] = max(0, unit["hp"] - int(unit["max_hp"] * 0.08))
					battle_log.append_text("\n%s 受到灼烧持续伤害" % unit["name"])
				elif status == "中毒":
					unit["hp"] = max(0, unit["hp"] - int(unit["max_hp"] * 0.06))
					battle_log.append_text("\n%s 受到中毒持续伤害" % unit["name"])
				unit["status"][status] -= 1
				if unit["status"][status] <= 0:
					unit["status"].erase(status)

func _cleanup_dead() -> void:
	allies = allies.filter(func(u: Dictionary): return u["hp"] > 0)
	enemies = enemies.filter(func(u: Dictionary): return u["hp"] > 0)
	turn_queue = turn_queue.filter(func(u: Dictionary): return u["hp"] > 0)
	_refresh_battle_lists()

func _check_battle_end() -> bool:
	if allies.is_empty():
		battle_active = false
		battle_log.append_text("\n[失败] 队伍被击败，可重新编队再挑战。")
		_refresh_stage_mode()
		return true
	if enemies.is_empty():
		battle_active = false
		var reward := 30 + floor * 10
		_apply_rewards(reward)
		battle_log.append_text("\n[胜利] 通关第%d层，获得全队经验 %d。" % [floor, reward])
		floor += 1
		if floor % 5 == 0:
			pending_boss_reform = true
			_restore_team_status()
			battle_log.append_text("\n[爬塔] 即将进入Boss层，允许重新编辑阵容，且角色状态已回满。")
		_refresh_stage_mode()
		_refresh_roster()
		return true
	return false

func _apply_rewards(exp_gain: int) -> void:
	var deployed_ids: Array[int] = []
	for hero in formation_slots:
		if hero != null:
			deployed_ids.append(hero["id"])
	for hero in heroes:
		if deployed_ids.has(hero["id"]):
			hero["exp"] += exp_gain
			while hero["exp"] >= EXP_PER_LEVEL:
				hero["exp"] -= EXP_PER_LEVEL
				hero["level"] += 1
				hero["max_hp"] += 12
				hero["atk"] += 3
				hero["def"] += 2
				hero["spd"] += 1
				hero["hp"] = hero["max_hp"]
				battle_log.append_text("\n[升级] %s 升到 Lv%d" % [hero["name"], hero["level"]])

func _restore_team_status() -> void:
	for hero in heroes:
		hero["hp"] = hero["max_hp"]
		hero["status"] = {}
		hero["buff_attack"] = 0.0
		hero["buff_defense"] = 0.0

func _hero_brief(hero: Dictionary) -> String:
	return "%s | Lv%d | %s/%s" % [hero["name"], hero["level"], hero["profession"], hero["talent"]]

func _battle_unit_text(unit: Dictionary) -> String:
	return "%s  HP:%d/%d  [%s]" % [unit["name"], unit["hp"], unit["max_hp"], unit["talent"]]

func _hero_detail(hero: Dictionary) -> String:
	var text := "[b]%s[/b]\n职业: %s\n天赋: %s\n等级: %d\nHP: %d/%d  攻:%d 防:%d 速:%d\n技能:\n" % [hero["name"], hero["profession"], hero["talent"], hero["level"], hero["hp"], hero["max_hp"], hero["atk"], hero["def"], hero["spd"]]
	for skill in hero["skills"]:
		text += "- %s\n" % skill["name"]
	text += "克制: %s 克制 %s" % [hero["talent"], TALENT_COUNTER[hero["talent"]]]
	return text
