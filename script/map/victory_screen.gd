extends Control


func _ready() -> void:
	var snap: Dictionary = PlayerState.pending_victory_snapshot
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[center][font_size=22][b]You cleared the run![/b][/font_size][/center]\n")
	var seed_v := int(snap.get("seed", 0))
	var gold_v := int(snap.get("gold", 0))
	lines.append("Seed: %d  ·  Gold: %d\n" % [seed_v, gold_v])
	lines.append("\n[font_size=16][b]Balls on the board (final battle)[/b][/font_size]\n")
	var balls: Array = snap.get("balls", []) as Array
	if balls.is_empty():
		lines.append("— No balls on the board at victory.\n")
	else:
		for row in balls:
			if row is Dictionary:
				var d: Dictionary = row
				var rk := int(d.get("rank", 0))
				var dmg := int(d.get("damage", 0))
				var lbl := str(d.get("label", "?"))
				lines.append("• Rank %d — %s — [b]%d[/b] damage dealt\n" % [rk, lbl, dmg])
	lines.append("\n[font_size=16][b]Damage by rank slot & ability (run)[/b][/font_size]\n")
	lines.append("When you swapped an ability mid-run, each version is listed separately.\n")
	var segs: Array = snap.get("rank_segments", []) as Array
	if segs.is_empty():
		lines.append("— No recorded rank-ability damage yet.\n")
	else:
		for seg in segs:
			if seg is Dictionary:
				var s: Dictionary = seg
				var r2 := int(s.get("rank", 0))
				var nm := str(s.get("name", s.get("kind", "?")))
				var dm := int(s.get("damage", 0))
				lines.append("• Rank %d — %s — [b]%d[/b] damage to enemies\n" % [r2, nm, dm])
	var body := get_node_or_null("Margin/VBox/RichTextBody") as RichTextLabel
	var txt := ""
	for part in lines:
		txt += str(part)
	if body != null:
		body.text = txt
	var btn := get_node_or_null("Margin/VBox/ContinueButton") as Button
	if btn != null and not btn.pressed.is_connected(_on_continue_pressed):
		btn.pressed.connect(_on_continue_pressed)


func _on_continue_pressed() -> void:
	PlayerState.pending_victory_snapshot.clear()
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("complete_current_room"):
		gm.complete_current_room()
