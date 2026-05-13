extends Control

const MAX_BOARD_LINES := 5
const MAX_DAMAGE_LINES := 6


func _ready() -> void:
	var snap: Dictionary = PlayerState.pending_victory_snapshot
	var balls := _sorted_board_rows(snap.get("balls", []) as Array)
	var damage_rows := _sorted_damage_rows(snap.get("rank_segments", []) as Array)
	var gold := int(snap.get("gold", 0))
	var seed := int(snap.get("seed", 0))
	var total_damage := _total_damage(damage_rows)

	_set_label("MetaLabel", "Seed %d" % seed)
	_set_label("StatsLabel", "Gold %s   |   Damage %s   |   Best %s" % [
		_format_number(gold),
		_format_number(total_damage),
		_best_damage_label(damage_rows),
	])
	_set_rich_text("BoardBody", _board_text(balls))
	_set_rich_text("DamageBody", _damage_text(damage_rows))
	_connect_continue_button()


func _sorted_board_rows(source: Array) -> Array:
	var rows: Array = []
	for item in source:
		if item is Dictionary:
			rows.append((item as Dictionary).duplicate())
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("rank", 0)) < int(b.get("rank", 0))
	)
	return rows


func _sorted_damage_rows(source: Array) -> Array:
	var rows: Array = []
	for item in source:
		if item is Dictionary and int((item as Dictionary).get("damage", 0)) > 0:
			rows.append((item as Dictionary).duplicate())
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("damage", 0)) > int(b.get("damage", 0))
	)
	return rows


func _board_text(rows: Array) -> String:
	if rows.is_empty():
		return "No balls recorded at victory."
	var lines: PackedStringArray = []
	var count: int = min(rows.size(), MAX_BOARD_LINES)
	for i in range(count):
		var row: Dictionary = rows[i]
		lines.append("Rank %d  %s  %s dmg" % [
			int(row.get("rank", 0)),
			_trim(str(row.get("label", "Ball")), 24),
			_format_number(int(row.get("damage", 0))),
		])
	if rows.size() > MAX_BOARD_LINES:
		lines.append("+ %d more" % (rows.size() - MAX_BOARD_LINES))
	return "\n".join(lines)


func _damage_text(rows: Array) -> String:
	if rows.is_empty():
		return "No rank damage recorded."
	var lines: PackedStringArray = []
	var count: int = min(rows.size(), MAX_DAMAGE_LINES)
	for i in range(count):
		var row: Dictionary = rows[i]
		lines.append("Rank %d  %s  %s" % [
			int(row.get("rank", 0)),
			_trim(str(row.get("name", row.get("kind", "Ability"))), 24),
			_format_number(int(row.get("damage", 0))),
		])
	if rows.size() > MAX_DAMAGE_LINES:
		lines.append("+ %d more" % (rows.size() - MAX_DAMAGE_LINES))
	return "\n".join(lines)


func _connect_continue_button() -> void:
	var btn := find_child("ContinueButton", true, false) as Button
	if btn != null and not btn.pressed.is_connected(_on_continue_pressed):
		btn.pressed.connect(_on_continue_pressed)


func _on_continue_pressed() -> void:
	PlayerState.pending_victory_snapshot.clear()
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("complete_run_victory_to_menu"):
		gm.complete_run_victory_to_menu()
		return
	get_tree().change_scene_to_file("res://scenes/menu_screen.tscn")


func _best_damage_label(rows: Array) -> String:
	if rows.is_empty():
		return "-"
	var best: Dictionary = rows[0]
	return "Rank %d %s" % [
		int(best.get("rank", 0)),
		_trim(str(best.get("name", best.get("kind", ""))), 14),
	]


func _total_damage(rows: Array) -> int:
	var total := 0
	for row in rows:
		if row is Dictionary:
			total += int((row as Dictionary).get("damage", 0))
	return total


func _format_number(value: int) -> String:
	var sign := "-" if value < 0 else ""
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.substr(digits.length() - 3, 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return sign + digits + out


func _trim(value: String, max_chars: int) -> String:
	var clean := value.strip_edges()
	if clean.is_empty():
		return "-"
	if clean.length() <= max_chars:
		return clean
	return clean.substr(0, max_chars - 3) + "..."


func _set_label(node_name: String, value: String) -> void:
	var lbl := find_child(node_name, true, false) as Label
	if lbl != null:
		lbl.text = value


func _set_rich_text(node_name: String, value: String) -> void:
	var body := find_child(node_name, true, false) as RichTextLabel
	if body != null:
		body.text = value
