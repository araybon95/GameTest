extends Control
## Ashen Expedition — a Slay-the-Spire-style deckbuilder with Darkest Dungeon
## flavour: a party of three heroes, separate decks, HP + Block + Stress, enemy
## intents, Death's Door, and the Stress resolve test (Virtue / Affliction).
##
## The saved scene supplies the interactive nodes and their signal connections;
## this script lays out the game and wires in the generated artwork.

const BG = "#0D0A0C"
const PANEL = "#211519"
const GOLD = "#8F4546"
const IVORY = "#EADDD0"
const MUTED = "#B5A2A3"
const RED = "#DF7870"
const GREEN = "#AAA487"
const VIRTUE_COLOR = "#8FB07A"
const AFFLICTION_COLOR = "#C25A55"

const HERO_ORDER: Array[String] = ["Warden", "Ranger", "Occultist"]

# Artwork lives in res://assets/generated/. Missing files fall back to text.
const ART_BACKGROUND = "res://assets/generated/bg_crypt.png"
const ART_ENEMY = "res://assets/generated/enemy_hollow_villager.png"
const CARD_ART_DIR = "res://assets/generated/"
const HERO_ART = {
	"Warden": "res://assets/generated/hero_warden.png",
	"Ranger": "res://assets/generated/hero_ranger.png",
	"Occultist": "res://assets/generated/hero_occultist.png",
}

const STARTER_DECKS = {
	"Warden": ["wd_slash", "wd_slash", "wd_slash", "wd_slash", "wd_guard", "wd_guard", "wd_guard", "wd_bash", "wd_rally", "wd_heavy"],
	"Ranger": ["rg_quick", "rg_quick", "rg_quick", "rg_quick", "rg_dodge", "rg_dodge", "rg_dodge", "rg_mark", "rg_pierce", "rg_volley"],
	"Occultist": ["oc_hex", "oc_hex", "oc_hex", "oc_hex", "oc_veil", "oc_veil", "oc_veil", "oc_weak", "oc_drain", "oc_blast"]
}

# Change card data here when balancing. The card art filename matches its ID.
# Effects: attack, block, attack_block, team_block, mark, pierce, weaken,
#          drain, stress_attack.
const CARD_DATA = {
	"wd_slash": {"name": "Slash", "cost": 1, "effect": "attack", "damage": 6, "description": "Deal 6 damage."},
	"wd_guard": {"name": "Guard", "cost": 1, "effect": "block", "block": 6, "description": "Gain 6 Block."},
	"wd_bash": {"name": "Shield Bash", "cost": 2, "effect": "attack_block", "damage": 8, "block": 4, "description": "Deal 8 damage. Gain 4 Block."},
	"wd_rally": {"name": "Rally", "cost": 1, "effect": "team_block", "block": 3, "description": "All standing heroes gain 3 Block."},
	"wd_heavy": {"name": "Heavy Strike", "cost": 2, "effect": "attack", "damage": 13, "description": "Deal 13 damage."},
	"rg_quick": {"name": "Quick Shot", "cost": 1, "effect": "attack", "damage": 5, "description": "Deal 5 damage."},
	"rg_dodge": {"name": "Dodge", "cost": 1, "effect": "block", "block": 5, "description": "Gain 5 Block."},
	"rg_mark": {"name": "Mark Target", "cost": 1, "effect": "mark", "bonus": 4, "description": "Next hit deals +4 damage."},
	"rg_pierce": {"name": "Piercing Arrow", "cost": 2, "effect": "pierce", "damage": 10, "description": "Deal 10 damage. Ignore Block."},
	"rg_volley": {"name": "Volley", "cost": 2, "effect": "attack", "damage": 9, "description": "Deal 9 damage."},
	"oc_hex": {"name": "Hex Bolt", "cost": 1, "effect": "attack", "damage": 5, "description": "Deal 5 damage."},
	"oc_veil": {"name": "Veil", "cost": 1, "effect": "block", "block": 5, "description": "Gain 5 Block."},
	"oc_weak": {"name": "Withering Hex", "cost": 1, "effect": "weaken", "description": "Reduce enemy attack by 3 for 2 turns."},
	"oc_drain": {"name": "Soul Drain", "cost": 2, "effect": "drain", "damage": 8, "heal": 4, "description": "Deal 8 damage. Heal 4 HP."},
	"oc_blast": {"name": "Dark Blast", "cost": 2, "effect": "stress_attack", "damage": 14, "stress": 8, "description": "Deal 14 damage. Gain 8 Stress."}
}

const AFFLICTIONS: Array[String] = ["Paranoid", "Masochistic", "Abusive", "Irrational", "Hopeless", "Fearful"]
const VIRTUES: Array[String] = ["Stalwart", "Courageous", "Focused", "Powerful", "Vigorous", "Vigilant"]
const VIRTUE_CHANCE = 0.25

const STARTING_HP = {"Warden": 55, "Ranger": 38, "Occultist": 34}
const ENEMY_NAME = "Hollow Villager"
const ENEMY_MAX_HP = 68

var hero_state: Dictionary = {}
var hero_buttons: Dictionary = {}
var hero_name_labels: Dictionary = {}
var hero_stat_labels: Dictionary = {}
var selected_hero: String = "Warden"

var enemy_hp: int = ENEMY_MAX_HP
var enemy_block: int = 0
var enemy_mark_bonus: int = 0
var enemy_weak_rounds: int = 0
var round_number: int = 1
var battle_over: bool = false
var battle_log: Array[String] = []

var round_label: Label
var hand_title: Label
var hand_container: HBoxContainer
var log_container: VBoxContainer
var end_turn_button: Button
var enemy_label: Label
var enemy_intent_label: Label
var enemy_art: Control


func _ready() -> void:
	# Bind the saved scene UI; keep node paths stable for editor connections.
	_build_interface()
	_start_battle()


func _start_battle() -> void:
	battle_over = false
	round_number = 1
	enemy_hp = ENEMY_MAX_HP
	enemy_block = 0
	enemy_mark_bonus = 0
	enemy_weak_rounds = 0
	selected_hero = "Warden"
	battle_log.clear()
	hero_state.clear()

	for hero_name in HERO_ORDER:
		var starting_cards: Array = STARTER_DECKS[hero_name].duplicate()
		starting_cards.shuffle()
		hero_state[hero_name] = {
			"hp": STARTING_HP[hero_name],
			"max_hp": STARTING_HP[hero_name],
			"block": 0,
			"ap": 2,
			"stress": 0,
			"draw": starting_cards,
			"hand": [],
			"discard": [],
			"dead": false,
			"deaths_door": false,
			"damage_mod": 0,
			"stress_per_turn": 0,
			"resolved": false,
			"resolve_tag": "",
			"resolve_type": ""
		}
		_draw_cards(hero_name, 3)

	_add_log("The Old Road: a %s blocks the path." % ENEMY_NAME)
	_add_log("Three heroes. Three decks. One party turn.")
	_add_log("At 100 Stress a hero faces a resolve test — Virtue or Affliction.")
	_refresh_all()


# -------------------- PARTY STATE --------------------

func _is_standing(hero_name: String) -> bool:
	return not bool(hero_state[hero_name]["dead"])


func _standing_heroes() -> Array:
	var out: Array = []
	for hero_name in HERO_ORDER:
		if _is_standing(hero_name):
			out.append(hero_name)
	return out


func _draw_cards(hero_name: String, amount: int) -> void:
	var state: Dictionary = hero_state[hero_name]
	for i in range(amount):
		if state["draw"].is_empty():
			if state["discard"].is_empty():
				break
			state["draw"] = state["discard"].duplicate()
			state["discard"].clear()
			state["draw"].shuffle()
			_add_log(hero_name + " reshuffles their discard pile.")
		state["hand"].append(state["draw"].pop_back())


func _select_hero(hero_name: String) -> void:
	if battle_over or not _is_standing(hero_name):
		return
	selected_hero = hero_name
	_refresh_all()


func _play_card(hero_name: String, card_index: int) -> void:
	if battle_over or hero_name != selected_hero:
		return
	var state: Dictionary = hero_state[hero_name]
	if not _is_standing(hero_name):
		return
	if card_index < 0 or card_index >= state["hand"].size():
		return
	var card_id: String = str(state["hand"][card_index])
	var card: Dictionary = CARD_DATA[card_id]
	if int(state["ap"]) < int(card["cost"]):
		return

	state["ap"] = int(state["ap"]) - int(card["cost"])
	state["discard"].append(state["hand"].pop_at(card_index))
	_add_log("%s plays %s." % [hero_name, card["name"]])
	_resolve_card(hero_name, card)

	if enemy_hp <= 0:
		battle_over = true
		_add_log("VICTORY — the %s falls." % ENEMY_NAME)
	_refresh_all()


func _resolve_card(hero_name: String, card: Dictionary) -> void:
	var state: Dictionary = hero_state[hero_name]
	var bonus: int = int(state["damage_mod"])
	match str(card["effect"]):
		"attack":
			_deal_enemy_damage(int(card["damage"]) + bonus)
		"pierce":
			_deal_enemy_damage(int(card["damage"]) + bonus, true)
		"block":
			_gain_block(hero_name, int(card["block"]))
		"attack_block":
			_deal_enemy_damage(int(card["damage"]) + bonus)
			_gain_block(hero_name, int(card["block"]))
		"team_block":
			for ally in _standing_heroes():
				_gain_block(ally, int(card["block"]))
		"mark":
			enemy_mark_bonus += int(card["bonus"])
			_add_log("Enemy marked: next hit +%d." % enemy_mark_bonus)
		"weaken":
			enemy_weak_rounds = 2
			_add_log("Enemy weakened for 2 attacks.")
		"drain":
			_deal_enemy_damage(int(card["damage"]) + bonus)
			_heal_hero(hero_name, int(card["heal"]))
		"stress_attack":
			_deal_enemy_damage(int(card["damage"]) + bonus)
			_gain_stress(hero_name, int(card["stress"]))


# -------------------- ENEMY --------------------

func _enemy_attack_power() -> int:
	var base: int = 7 + ((round_number - 1) % 3) * 2
	if enemy_weak_rounds > 0:
		base = maxi(0, base - 3)
	return base


func _enemy_target() -> String:
	var standing: Array = _standing_heroes()
	if standing.is_empty():
		return ""
	return str(standing[(round_number - 1) % standing.size()])


func _enemy_action() -> void:
	# Every fourth turn the enemy braces instead of striking.
	if (round_number - 1) % 4 == 3:
		enemy_block += 8
		_add_log("%s braces: gains 8 Block." % ENEMY_NAME)
		return

	var target: String = _enemy_target()
	if target == "":
		return
	var attack: int = _enemy_attack_power()
	if enemy_weak_rounds > 0:
		enemy_weak_rounds -= 1
	_apply_damage(target, attack)
	_add_log("%s attacks %s for %d." % [ENEMY_NAME, target, attack])
	_gain_stress(target, 2)


func _enemy_intent_text() -> String:
	if battle_over:
		return "Encounter finished"
	if (round_number - 1) % 4 == 3:
		return "INTENT: Brace · Gain 8 Block"
	var target: String = _enemy_target()
	if target == "":
		return "INTENT: —"
	return "INTENT: Strike %s for %d" % [target, _enemy_attack_power()]


# -------------------- DAMAGE / HEAL / STRESS --------------------

func _deal_enemy_damage(amount: int, ignore_block: bool = false) -> void:
	var total: int = amount + enemy_mark_bonus
	enemy_mark_bonus = 0
	var absorbed: int = 0
	if not ignore_block:
		absorbed = mini(total, enemy_block)
		enemy_block -= absorbed
	var damage: int = total - absorbed
	enemy_hp = maxi(0, enemy_hp - damage)
	_add_log("Villager takes %d damage%s." % [damage, " (%d blocked)" % absorbed if absorbed > 0 else ""])
	_flash(enemy_art, Color("#E78A84"))


func _apply_damage(hero_name: String, amount: int) -> void:
	var state: Dictionary = hero_state[hero_name]
	if bool(state["dead"]):
		return
	var absorbed: int = mini(amount, int(state["block"]))
	state["block"] = int(state["block"]) - absorbed
	var damage: int = amount - absorbed
	if damage <= 0:
		_add_log("%s blocks the blow." % hero_name)
		_flash(hero_buttons[hero_name], Color("#C9C4B0"))
		return
	_flash(hero_buttons[hero_name], Color("#E78A84"))
	if bool(state["deaths_door"]) or int(state["hp"]) <= 0:
		state["dead"] = true
		state["deaths_door"] = false
		_add_log("%s is slain at Death's Door!" % hero_name)
		return
	var remaining: int = int(state["hp"]) - damage
	if remaining <= 0:
		state["hp"] = 0
		state["deaths_door"] = true
		_add_log("%s takes %d damage and stands at DEATH'S DOOR!" % [hero_name, damage])
	else:
		state["hp"] = remaining
		_add_log("%s takes %d damage%s." % [hero_name, damage, " (%d blocked)" % absorbed if absorbed > 0 else ""])


func _heal_hero(hero_name: String, amount: int) -> void:
	var state: Dictionary = hero_state[hero_name]
	if bool(state["dead"]):
		return
	var before: int = int(state["hp"])
	state["hp"] = mini(int(state["max_hp"]), before + amount)
	if int(state["hp"]) > 0:
		state["deaths_door"] = false
	_add_log("%s heals %d HP." % [hero_name, int(state["hp"]) - before])


func _gain_block(hero_name: String, amount: int) -> void:
	hero_state[hero_name]["block"] = int(hero_state[hero_name]["block"]) + amount
	_add_log("%s gains %d Block." % [hero_name, amount])


func _gain_stress(hero_name: String, amount: int) -> void:
	var state: Dictionary = hero_state[hero_name]
	if bool(state["dead"]):
		return
	state["stress"] = mini(100, int(state["stress"]) + amount)
	if not bool(state["resolved"]) and int(state["stress"]) >= 100:
		_resolve_stress_test(hero_name)


func _resolve_stress_test(hero_name: String) -> void:
	var state: Dictionary = hero_state[hero_name]
	state["resolved"] = true
	if randf() < VIRTUE_CHANCE:
		var virtue: String = VIRTUES[randi() % VIRTUES.size()]
		state["resolve_tag"] = virtue
		state["resolve_type"] = "virtue"
		state["damage_mod"] = int(state["damage_mod"]) + 2
		state["stress"] = 45
		_add_log("RESOLVE TEST — %s is VIRTUOUS (%s)!" % [hero_name, virtue])
		_add_log("%s fights on: +2 damage, Stress steadied to 45." % hero_name)
		_heal_hero(hero_name, 6)
	else:
		var affliction: String = AFFLICTIONS[randi() % AFFLICTIONS.size()]
		state["resolve_tag"] = affliction
		state["resolve_type"] = "affliction"
		state["damage_mod"] = int(state["damage_mod"]) - 2
		state["stress_per_turn"] = int(state["stress_per_turn"]) + 3
		state["stress"] = 100
		_add_log("RESOLVE TEST — %s is AFFLICTED (%s)!" % [hero_name, affliction])
		_add_log("%s deals -2 damage and suffers +3 Stress each turn." % hero_name)
	var tint: Color = Color(VIRTUE_COLOR) if state["resolve_type"] == "virtue" else Color(AFFLICTION_COLOR)
	_flash(hero_buttons[hero_name], tint)


# -------------------- TURN FLOW --------------------

func _end_turn() -> void:
	if battle_over:
		return

	_enemy_action()
	if enemy_hp <= 0:
		battle_over = true
		_add_log("VICTORY — the %s falls." % ENEMY_NAME)

	if not battle_over and _standing_heroes().is_empty():
		battle_over = true
		_add_log("DEFEAT — the party has fallen.")

	if battle_over:
		_refresh_all()
		return

	# Block wears off; standing heroes refill AP, gain on-going stress and draw.
	for hero_name in HERO_ORDER:
		var state: Dictionary = hero_state[hero_name]
		state["block"] = 0
		if _is_standing(hero_name):
			state["ap"] = 2
			_gain_stress(hero_name, int(state["stress_per_turn"]))
			_draw_cards(hero_name, 1)
		else:
			state["ap"] = 0

	round_number += 1
	if not _is_standing(selected_hero):
		var survivors: Array = _standing_heroes()
		if not survivors.is_empty():
			selected_hero = str(survivors[0])
	_add_log("Round %d begins." % round_number)
	_refresh_all()


# -------------------- VIEW REFRESH --------------------

func _refresh_all() -> void:
	round_label.text = "ROUND %d" % round_number
	var hero: Dictionary = hero_state[selected_hero]
	hand_title.text = "%s  ·  %d/2 AP  ·  Draw %d  ·  Hand %d  ·  Discard %d" % [
		selected_hero, int(hero["ap"]), hero["draw"].size(), hero["hand"].size(), hero["discard"].size()
	]
	for hero_name in HERO_ORDER:
		var state: Dictionary = hero_state[hero_name]
		var tag: String = ""
		if str(state["resolve_tag"]) != "":
			tag = "  [" + str(state["resolve_tag"]).to_upper() + "]"
		var name_label: Label = hero_name_labels[hero_name]
		name_label.text = ("▶ " if hero_name == selected_hero else "") + hero_name.to_upper() + tag
		if bool(state["deaths_door"]):
			name_label.add_theme_color_override("font_color", Color(RED))
		elif state["resolve_type"] == "virtue":
			name_label.add_theme_color_override("font_color", Color(VIRTUE_COLOR))
		elif state["resolve_type"] == "affliction":
			name_label.add_theme_color_override("font_color", Color(AFFLICTION_COLOR))
		else:
			name_label.add_theme_color_override("font_color", Color(IVORY))

		var status: String = "AP %d/2  ·  Blk %d  ·  Stress %d" % [
			int(state["ap"]), int(state["block"]), int(state["stress"])
		]
		if bool(state["deaths_door"]):
			status = "DEATH'S DOOR  ·  one more blow ends them"
		elif bool(state["dead"]):
			status = "SLAIN"
		hero_stat_labels[hero_name].text = status

		var button: Button = hero_buttons[hero_name]
		var health: ProgressBar = button.get_node("HealthBar")
		health.max_value = int(state["max_hp"])
		health.value = int(state["hp"])
		button.get_node("StressBar").value = int(state["stress"])
		button.disabled = battle_over or not _is_standing(hero_name)
		button.modulate = Color(0.55, 0.55, 0.6) if bool(state["dead"]) else Color.WHITE

	enemy_label.text = "%s\nHP %d / %d     Block %d%s" % [
		ENEMY_NAME.to_upper(), enemy_hp, ENEMY_MAX_HP, enemy_block,
		"     Mark +%d" % enemy_mark_bonus if enemy_mark_bonus > 0 else ""
	]
	$Enemy/HealthBar.max_value = ENEMY_MAX_HP
	$Enemy/HealthBar.value = enemy_hp
	enemy_intent_label.text = _enemy_intent_text()
	end_turn_button.disabled = battle_over
	end_turn_button.text = "END PARTY TURN" if not battle_over else "BATTLE FINISHED"
	_refresh_hand()
	_refresh_log()


func _refresh_hand() -> void:
	for child in hand_container.get_children():
		hand_container.remove_child(child)
		child.queue_free()
	var hand: Array = hero_state[selected_hero]["hand"]
	for index in range(hand.size()):
		var card_id: String = str(hand[index])
		var card: Dictionary = CARD_DATA[card_id]
		var view: Button = _create_card_view(card_id, card)
		view.disabled = battle_over or int(hero_state[selected_hero]["ap"]) < int(card["cost"])
		view.pressed.connect(_play_card.bind(selected_hero, index))
		hand_container.add_child(view)
	if hand.is_empty():
		hand_container.add_child(_make_label("No cards in hand. End the party turn to draw again.", 23, Color(MUTED)))


func _refresh_log() -> void:
	for child in log_container.get_children():
		log_container.remove_child(child)
		child.queue_free()
	var first: int = maxi(0, battle_log.size() - 10)
	for i in range(first, battle_log.size()):
		var label: Label = _make_label("• " + battle_log[i], 19, Color(MUTED))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		log_container.add_child(label)


func _add_log(message: String) -> void:
	battle_log.append(message)


func _flash(target: Control, tint: Color) -> void:
	if target == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(target, "modulate", tint, 0.10)
	tween.tween_property(target, "modulate", Color.WHITE, 0.20)


# -------------------- INTERFACE / ART --------------------

func _build_interface() -> void:
	round_label = $RoundLabel
	hand_title = $HandTitle
	hand_container = $CardHand/Cards
	log_container = $BattleLog
	end_turn_button = $EndTurnButton
	enemy_label = $Enemy/EnemyInfo
	enemy_intent_label = $Enemy/EnemyIntent
	enemy_art = $Enemy

	_add_title()
	_build_background()
	_layout_regions()
	_build_enemy()
	for hero_name in HERO_ORDER:
		_build_hero(hero_name)

	enemy_intent_label.add_theme_color_override("font_color", Color(RED))
	end_turn_button.add_theme_font_size_override("font_size", 24)
	round_label.add_theme_color_override("font_color", Color(GOLD))
	hand_title.add_theme_color_override("font_color", Color(GOLD))
	for hero_name in HERO_ORDER:
		var button: Button = hero_buttons[hero_name]
		_style_meter(button.get_node("HealthBar"), Color("#AF343C"))
		_style_meter(button.get_node("StressBar"), Color("#79435C"))
	_style_meter($Enemy/HealthBar, Color("#AF343C"))


func _add_title() -> void:
	var title: Label = _make_label("ASHEN  EXPEDITION", 34, Color(IVORY), true)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	title.position = Vector2(size.x * 0.5 - 260.0, 10.0)
	title.size = Vector2(520.0, 44.0)


func _build_background() -> void:
	var overlay: ColorRect = $Background
	overlay.color = Color(0.04, 0.03, 0.038, 0.62)
	var art := TextureRect.new()
	art.name = "BackgroundArt"
	art.texture = _load_texture(ART_BACKGROUND)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.z_index = -2
	add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _layout_regions() -> void:
	var heroes: HBoxContainer = $Heros
	heroes.anchor_left = 0.0
	heroes.anchor_top = 0.0
	heroes.anchor_right = 0.0
	heroes.anchor_bottom = 0.0
	heroes.offset_left = 452.0
	heroes.offset_top = 742.0
	heroes.offset_right = 1300.0
	heroes.offset_bottom = 1050.0

	var hand: ScrollContainer = $CardHand
	hand.anchor_left = 0.0
	hand.anchor_top = 0.0
	hand.anchor_right = 0.0
	hand.anchor_bottom = 0.0
	hand.offset_left = 16.0
	hand.offset_top = 330.0
	hand.offset_right = 770.0
	hand.offset_bottom = 700.0

	hand_title.position = Vector2(18.0, 292.0)
	hand_title.size = Vector2(320.0, 34.0)

	var log_box: VBoxContainer = $BattleLog
	log_box.offset_left = 1380.0
	log_box.offset_right = 1904.0

	end_turn_button.position = Vector2(1596.0, 968.0)
	end_turn_button.size = Vector2(300.0, 72.0)


func _build_enemy() -> void:
	var enemy: Button = $Enemy
	enemy.anchor_left = 0.0
	enemy.anchor_top = 0.0
	enemy.anchor_right = 0.0
	enemy.anchor_bottom = 0.0
	enemy.offset_left = 730.0
	enemy.offset_top = 96.0
	enemy.offset_right = 1190.0
	enemy.offset_bottom = 470.0

	var art := TextureRect.new()
	art.texture = _load_texture(ART_ENEMY)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy.add_child(art)
	enemy.move_child(art, 0)
	art.position = Vector2(110.0, 30.0)
	art.size = Vector2(240.0, 250.0)

	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.position = Vector2(8.0, 4.0)
	enemy_label.size = Vector2(444.0, 40.0)
	enemy_label.add_theme_font_size_override("font_size", 26)
	enemy_label.add_theme_color_override("font_color", Color(IVORY))
	enemy_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	enemy_label.add_theme_constant_override("shadow_offset_x", 2)
	enemy_label.add_theme_constant_override("shadow_offset_y", 2)

	enemy_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_intent_label.position = Vector2(8.0, 286.0)
	enemy_intent_label.size = Vector2(444.0, 40.0)
	enemy_intent_label.add_theme_font_size_override("font_size", 22)
	enemy_intent_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	enemy_intent_label.add_theme_constant_override("shadow_offset_x", 2)
	enemy_intent_label.add_theme_constant_override("shadow_offset_y", 2)

	var health: ProgressBar = enemy.get_node("HealthBar")
	health.anchor_top = 0.0
	health.anchor_bottom = 0.0
	health.anchor_right = 0.0
	health.position = Vector2(20.0, 336.0)
	health.size = Vector2(420.0, 20.0)


func _build_hero(hero_name: String) -> void:
	var button: Button = get_node("Heros/" + hero_name)
	hero_buttons[hero_name] = button
	button.text = ""
	button.custom_minimum_size = Vector2(280.0, 300.0)
	button.clip_text = false
	button.add_theme_font_size_override("font_size", 24)

	var portrait := TextureRect.new()
	portrait.texture = _load_texture(str(HERO_ART[hero_name]))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(portrait)
	portrait.position = Vector2(18.0, 10.0)
	portrait.size = Vector2(244.0, 176.0)

	var name_label: Label = _make_label("", 22, Color(IVORY), true)
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	button.add_child(name_label)
	name_label.position = Vector2(8.0, 188.0)
	name_label.size = Vector2(264.0, 30.0)
	hero_name_labels[hero_name] = name_label

	var health: ProgressBar = button.get_node("HealthBar")
	health.position = Vector2(20.0, 224.0)
	health.size = Vector2(240.0, 16.0)

	var stress: ProgressBar = button.get_node("StressBar")
	stress.position = Vector2(20.0, 246.0)
	stress.size = Vector2(240.0, 16.0)

	var stat_label: Label = _make_label("", 15, Color(MUTED), true)
	button.add_child(stat_label)
	stat_label.position = Vector2(6.0, 268.0)
	stat_label.size = Vector2(268.0, 28.0)
	hero_stat_labels[hero_name] = stat_label


func _create_card_view(card_id: String, card: Dictionary) -> Button:
	var button := _make_button("", Vector2(220.0, 296.0))
	button.tooltip_text = str(card["description"])
	var contents := VBoxContainer.new()
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 6)
	button.add_child(contents)
	# Anchors must be applied after the parent is set.
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_left = 12
	contents.offset_top = 10
	contents.offset_right = -12
	contents.offset_bottom = -10
	contents.add_child(_make_label("%s    ·    %d AP" % [str(card["name"]), int(card["cost"])], 18, Color(IVORY), true))
	var picture := _art_slot(contents, CARD_ART_DIR + card_id + ".png", str(card["effect"]).to_upper(), Vector2(188.0, 150.0))
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(_make_label(str(card["effect"]).to_upper(), 15, Color(GOLD), true))
	var description: Label = _make_label(str(card["description"]), 16, Color(IVORY), true)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contents.add_child(description)
	return button


func _art_slot(parent: Control, texture_path: String, fallback: String, min_size: Vector2) -> Control:
	var frame := _make_panel(Color("#25171D"))
	frame.custom_minimum_size = min_size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	var texture: Texture2D = _load_texture(texture_path)
	if texture != null:
		var picture := TextureRect.new()
		picture.texture = texture
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(picture)
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var placeholder := _make_label(fallback, 31, Color(GOLD), true)
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		frame.add_child(placeholder)
		placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return frame


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


# -------------------- STYLE HELPERS --------------------

func _style_meter(meter: ProgressBar, tint: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#100F12")
	background.set_corner_radius_all(3)
	background.border_color = Color(GOLD)
	background.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = tint
	fill.set_corner_radius_all(3)
	meter.add_theme_stylebox_override("background", background)
	meter.add_theme_stylebox_override("fill", fill)


func _make_panel(bg_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(bg_color, Color(GOLD)))
	return panel


func _make_label(value: String, font_size: int, color: Color, centered: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_button(value: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 23)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color(IVORY))
	var normal := _style(Color(PANEL), Color(GOLD))
	var hover := _style(Color("#452029"), Color("#D68177"))
	var pressed := _style(Color("#5D202D"), Color("#D68177"))
	var disabled := _style(Color("#171216"), Color("#4B343D"))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("#E6A095")))
	return button


func _style(fill: Color, outline: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = outline
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(14)
	return box


# -------------------- SIGNAL HANDLERS --------------------

func _on_warden_pressed() -> void:
	_select_hero("Warden")


func _on_ranger_pressed() -> void:
	_select_hero("Ranger")


func _on_occultist_pressed() -> void:
	_select_hero("Occultist")


func _on_end_turn_button_pressed() -> void:
	_end_turn()