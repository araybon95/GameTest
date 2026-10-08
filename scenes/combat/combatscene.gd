extends Control
## Ashen Expedition — self-contained combat vertical slice.
## Combat uses the saved scene nodes and their editor signal connections.
## Artwork is optional: drop transparent PNG files into the paths documented in README.md.

const BG = "#141922"
const PANEL = "#222B39"
const PANEL_DARK = "#1A2230"
const GOLD = "#B99A65"
const IVORY = "#F5E9D5"
const MUTED = "#BCC4CC"
const RED = "#E9978B"
const GREEN = "#A5D5B3"
const HERO_ORDER = ["Warden", "Ranger", "Occultist"]

const STARTER_DECKS = {
	"Warden": ["wd_slash", "wd_slash", "wd_slash", "wd_slash", "wd_guard", "wd_guard", "wd_guard", "wd_bash", "wd_rally", "wd_heavy"],
	"Ranger": ["rg_quick", "rg_quick", "rg_quick", "rg_quick", "rg_dodge", "rg_dodge", "rg_dodge", "rg_mark", "rg_pierce", "rg_volley"],
	"Occultist": ["oc_hex", "oc_hex", "oc_hex", "oc_hex", "oc_veil", "oc_veil", "oc_veil", "oc_weak", "oc_drain", "oc_blast"]
}

# Change card data here when balancing. The art filename matches its card ID.
# Effects supported: attack, block, attack_block, team_block, mark, pierce,
# weaken, drain, stress_attack. Each card is a unique instance in its owner's deck.
const CARD_DATA = {
	"wd_slash": {"name": "Slash", "cost": 1, "effect": "attack", "damage": 6, "description": "Deal 6 damage."},
	"wd_guard": {"name": "Guard", "cost": 1, "effect": "block", "block": 6, "description": "Gain 6 Block."},
	"wd_bash": {"name": "Shield Bash", "cost": 2, "effect": "attack_block", "damage": 8, "block": 4, "description": "Deal 8 damage. Gain 4 Block."},
	"wd_rally": {"name": "Rally", "cost": 1, "effect": "team_block", "block": 3, "description": "All living heroes gain 3 Block."},
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

var hero_state: Dictionary = {}
var hero_buttons: Dictionary = {}
var hero_portraits: Dictionary = {}
var selected_hero: String = "Warden"
var enemy_hp: int = 68
var enemy_block: int = 0
var enemy_mark_bonus: int = 0
var enemy_weak_rounds: int = 0
var round_number: int = 1
var battle_over: bool = false
var battle_log: Array[String] = []

var round_label: Label
var enemy_label: Label
var enemy_intent_label: Label
var enemy_art: Control
var hand_title: Label
var hand_container: HBoxContainer
var log_container: VBoxContainer
var end_turn_button: Button


func _ready() -> void:
	# Bind the saved scene UI; keep node paths stable for editor connections.
	_build_interface()
	_start_battle()


func _start_battle() -> void:
	battle_over = false
	round_number = 1
	enemy_hp = 68
	enemy_block = 0
	enemy_mark_bonus = 0
	enemy_weak_rounds = 0
	selected_hero = "Warden"
	battle_log.clear()
	hero_state.clear()

	var starting_hp := {"Warden": 55, "Ranger": 38, "Occultist": 34}
	for hero_name in HERO_ORDER:
		var starting_cards: Array = STARTER_DECKS[hero_name].duplicate()
		starting_cards.shuffle()
		hero_state[hero_name] = {
			"hp": starting_hp[hero_name],
			"max_hp": starting_hp[hero_name],
			"block": 0,
			"ap": 2,
			"stress": 0,
			"draw": starting_cards,
			"hand": [],
			"discard": []
		}
		_draw_cards(hero_name, 3)

	_add_log("The Old Road: a Hollow Villager blocks the path.")
	_add_log("Three heroes. Three separate decks. One party turn.")
	_refresh_all()


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
	if battle_over or int(hero_state[hero_name]["hp"]) <= 0:
		return
	selected_hero = hero_name
	_refresh_all()


func _play_card(hero_name: String, card_index: int) -> void:
	if battle_over or hero_name != selected_hero:
		return
	var state: Dictionary = hero_state[hero_name]
	if int(state["hp"]) <= 0:
		return
	if card_index < 0 or card_index >= state["hand"].size():
		return
	var card_id: String = str(state["hand"][card_index])
	var card: Dictionary = CARD_DATA[card_id]
	if int(state["ap"]) < int(card["cost"]):
		return

	state["ap"] -= int(card["cost"])
	state["discard"].append(state["hand"].pop_at(card_index))
	_add_log("%s plays %s." % [hero_name, card["name"]])
	_resolve_card(hero_name, card)

	if enemy_hp <= 0:
		battle_over = true
		_add_log("VICTORY — the Hollow Villager falls.")
	_refresh_all()


func _resolve_card(hero_name: String, card: Dictionary) -> void:
	var effect: String = str(card["effect"])
	match effect:
		"attack":
			_deal_enemy_damage(int(card["damage"]))
		"pierce":
			_deal_enemy_damage(int(card["damage"]), true)
		"block":
			_gain_block(hero_name, int(card["block"]))
		"attack_block":
			_deal_enemy_damage(int(card["damage"]))
			_gain_block(hero_name, int(card["block"]))
		"team_block":
			for ally in HERO_ORDER:
				if int(hero_state[ally]["hp"]) > 0:
					_gain_block(ally, int(card["block"]))
		"mark":
			enemy_mark_bonus += int(card["bonus"])
			_add_log("Enemy marked: next hit +%d." % enemy_mark_bonus)
		"weaken":
			enemy_weak_rounds = 2
			_add_log("Enemy weakened for 2 attacks.")
		"drain":
			_deal_enemy_damage(int(card["damage"]))
			var drain_state: Dictionary = hero_state[hero_name]
			var before: int = int(drain_state["hp"])
			drain_state["hp"] = mini(int(drain_state["max_hp"]), before + int(card["heal"]))
			_add_log(hero_name + " heals %d HP." % (int(drain_state["hp"]) - before))
		"stress_attack":
			_deal_enemy_damage(int(card["damage"]))
			var blast_state: Dictionary = hero_state[hero_name]
			blast_state["stress"] = mini(100, int(blast_state["stress"]) + int(card["stress"]))
			_add_log(hero_name + " gains %d Stress." % int(card["stress"]))


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


func _gain_block(hero_name: String, amount: int) -> void:
	hero_state[hero_name]["block"] += amount
	_add_log(hero_name + " gains %d Block." % amount)


func _end_turn() -> void:
	if battle_over:
		return

	_enemy_action()
	if battle_over:
		_refresh_all()
		return

	# Block wears off after the enemy action. Every surviving hero refills AP.
	for hero_name in HERO_ORDER:
		var state: Dictionary = hero_state[hero_name]
		state["block"] = 0
		if int(state["hp"]) > 0:
			state["ap"] = 2
			_draw_cards(hero_name, 1)
		else:
			state["ap"] = 0

	round_number += 1
	if int(hero_state[selected_hero]["hp"]) <= 0:
		for hero_name in HERO_ORDER:
			if int(hero_state[hero_name]["hp"]) > 0:
				selected_hero = hero_name
				break
	_add_log("Round %d begins." % round_number)
	_refresh_all()


func _enemy_action() -> void:
	# The third turn in the cycle is defensive; all other turns attack.
	if (round_number - 1) % 4 == 2:
		enemy_block = 8
		_add_log("Hollow Villager braces: gains 8 Block.")
		return

	var target: String = HERO_ORDER[(round_number - 1) % HERO_ORDER.size()]
	if int(hero_state[target]["hp"]) <= 0:
		for candidate in HERO_ORDER:
			if int(hero_state[candidate]["hp"]) > 0:
				target = candidate
				break
	var attack: int = 7 + ((round_number - 1) % 3) * 2
	if enemy_weak_rounds > 0:
		attack = maxi(0, attack - 3)
		enemy_weak_rounds -= 1
	var state: Dictionary = hero_state[target]
	var absorbed: int = mini(attack, int(state["block"]))
	state["block"] -= absorbed
	var damage: int = attack - absorbed
	state["hp"] = maxi(0, int(state["hp"]) - damage)
	_add_log("Villager attacks %s: %d damage (%d blocked)." % [target, damage, absorbed])
	_flash(hero_portraits[target], Color("#E78A84"))
	if int(state["hp"]) == 0:
		_add_log(target + " has fallen!")

	var any_survivor: bool = false
	for hero_name in HERO_ORDER:
		if int(hero_state[hero_name]["hp"]) > 0:
			any_survivor = true
	if not any_survivor:
		battle_over = true
		_add_log("DEFEAT — the party has fallen.")


func _enemy_intent_text() -> String:
	if battle_over:
		return "Encounter finished"
	if (round_number - 1) % 4 == 2:
		return "INTENT: Brace · Gain 8 Block"
	var target: String = HERO_ORDER[(round_number - 1) % HERO_ORDER.size()]
	if int(hero_state[target]["hp"]) <= 0:
		for candidate in HERO_ORDER:
			if int(hero_state[candidate]["hp"]) > 0:
				target = candidate
				break
	var damage: int = 7 + ((round_number - 1) % 3) * 2
	if enemy_weak_rounds > 0:
		damage = maxi(0, damage - 3)
	return "INTENT: Attack %s for %d" % [target, damage]


func _refresh_all() -> void:
	round_label.text = "ROUND %d" % round_number
	var hero: Dictionary = hero_state[selected_hero]
	hand_title.text = "%s  ·  %d/2 AP  ·  Draw %d  ·  Hand %d  ·  Discard %d" % [
		selected_hero, int(hero["ap"]), hero["draw"].size(), hero["hand"].size(), hero["discard"].size()
	]
	for hero_name in HERO_ORDER:
		var state: Dictionary = hero_state[hero_name]
		var button: Button = hero_buttons[hero_name]
		button.text = "%s%s\nHP %d/%d    Block %d    AP %d/2\nStress %d/100" % [
			"▶ " if hero_name == selected_hero else "", hero_name.to_upper(),
			int(state["hp"]), int(state["max_hp"]), int(state["block"]),
			int(state["ap"]), int(state["stress"])
		]
		var health: ProgressBar = button.get_node("HealthBar")
		health.max_value = int(state["max_hp"])
		health.value = int(state["hp"])
		button.get_node("StressBar").value = int(state["stress"])
		button.disabled = battle_over or int(state["hp"]) <= 0
	enemy_label.text = "HOLLOW VILLAGER\nHP %d / 68     Block %d%s" % [
		enemy_hp, enemy_block, "     Mark +%d" % enemy_mark_bonus if enemy_mark_bonus > 0 else ""
	]
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
	var first: int = maxi(0, battle_log.size() - 8)
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
	tween.tween_property(target, "modulate", Color.WHITE, 0.18)


# -------------------- UI / ART PLACEHOLDERS --------------------
# To replace art, put PNG files at the documented paths and relaunch the scene.
# _flash is the simple animation hook: later replace it with AnimationPlayer.

func _build_interface() -> void:
	round_label = $RoundLabel
	hand_title = $HandTitle
	hand_container = $CardHand/Cards
	log_container = $BattleLog
	end_turn_button = $EndTurnButton
	enemy_label = $EnemyInfo
	enemy_intent_label = $EnemyIntent
	enemy_art = $Enemy
	$Background.color = Color(BG)
	for hero_name in HERO_ORDER:
		var button: Button = get_node("Heros/" + hero_name)
		hero_buttons[hero_name] = button
		hero_portraits[hero_name] = button
		_style_meter(button.get_node("HealthBar"), Color("#A44542"))
		_style_meter(button.get_node("StressBar"), Color("#927CAD"))
	_style_meter($Enemy/HealthBar, Color("#A44542"))


func _style_meter(meter: ProgressBar, tint: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#100F12")
	background.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = tint
	fill.set_corner_radius_all(3)
	meter.add_theme_stylebox_override("background", background)
	meter.add_theme_stylebox_override("fill", fill)


func _on_warden_pressed() -> void:
	_select_hero("Warden")


func _on_ranger_pressed() -> void:
	_select_hero("Ranger")


func _on_occultist_pressed() -> void:
	_select_hero("Occultist")


func _on_end_turn_button_pressed() -> void:
	_end_turn()


func _create_card_view(card_id: String, card: Dictionary) -> Button:
	var button := _make_button("", Vector2(220, 244))
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
	contents.add_child(_make_label("%s    ·    %d AP" % [str(card["name"]), int(card["cost"])], 19, Color(IVORY), true))
	var picture := _art_slot(contents, "res://assets/cards/%s.png" % card_id, str(card["effect"]).to_upper(), Vector2(188, 102))
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(_make_label(str(card["effect"]).to_upper(), 16, Color(GOLD), true))
	var description: Label = _make_label(str(card["description"]), 17, Color(IVORY), true)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contents.add_child(description)
	return button


func _art_slot(parent: Control, texture_path: String, fallback: String, min_size: Vector2) -> Control:
	var frame := _make_panel(Color("#303848"))
	frame.custom_minimum_size = min_size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	if ResourceLoader.exists(texture_path):
		var picture := TextureRect.new()
		picture.texture = load(texture_path)
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


func _make_panel(bg_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(bg_color, Color(GOLD)))
	return panel


func _make_label(value: String, size: int, color: Color, centered: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
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
	var hover := _style(Color("#3A475B"), Color("#DDC58B"))
	var pressed := _style(Color("#574934"), Color("#DDC58B"))
	var disabled := _style(Color("#343941"), Color("#6E7276"))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("#EADCB7")))
	return button


func _style(fill: Color, outline: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = outline
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(14)
	return box
