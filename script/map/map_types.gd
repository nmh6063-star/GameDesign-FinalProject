extends RefCounted
class_name MapTypes

enum RoomType {
	START,
	BATTLE,
	ELITE,
	EVENT,
	SHOP,
	REST,
	TREASURE,
	MIDDLE_BOSS,
	FINAL_BOSS,
}

const REGULAR_TYPES := [
	RoomType.BATTLE,
	RoomType.ELITE,
	RoomType.EVENT,
	RoomType.SHOP,
	RoomType.REST,
	RoomType.TREASURE,
]

const LABELS := {
	RoomType.START: "Start",
	RoomType.BATTLE: "Battle",
	RoomType.ELITE: "Elite",
	RoomType.EVENT: "Event",
	RoomType.SHOP: "Shop",
	RoomType.REST: "Rest",
	RoomType.TREASURE: "Treasure",
	RoomType.MIDDLE_BOSS: "Middle Boss",
	RoomType.FINAL_BOSS: "Final Boss",
}

const MARKS := {
	RoomType.START: "ST",
	RoomType.BATTLE: "BT",
	RoomType.ELITE: "EL",
	RoomType.EVENT: "EV",
	RoomType.SHOP: "SH",
	RoomType.REST: "RS",
	RoomType.TREASURE: "TR",
	RoomType.MIDDLE_BOSS: "MB",
	RoomType.FINAL_BOSS: "FB",
}

const ICONS := {
	RoomType.START: "@",
	RoomType.BATTLE: "X",
	RoomType.ELITE: "!",
	RoomType.EVENT: "?",
	RoomType.SHOP: "$",
	RoomType.REST: "+",
	RoomType.TREASURE: "T",
	RoomType.MIDDLE_BOSS: "M",
	RoomType.FINAL_BOSS: "B",
}

const COLORS := {
	RoomType.START: Color("e7d59b"),
	RoomType.BATTLE: Color("f06a7b"),
	RoomType.ELITE: Color("ff7b39"),
	RoomType.EVENT: Color("8f78d8"),
	RoomType.SHOP: Color("59c79a"),
	RoomType.REST: Color("73c8f2"),
	RoomType.TREASURE: Color("f1c24e"),
	RoomType.MIDDLE_BOSS: Color("d94d4d"),
	RoomType.FINAL_BOSS: Color("b01c42"),
}


static func label(room_type: int) -> String:
	return LABELS.get(room_type, "Unknown")


static func mark(room_type: int) -> String:
	return MARKS.get(room_type, "??")


static func icon(room_type: int) -> String:
	return ICONS.get(room_type, "?")


static func color(room_type: int) -> Color:
	return COLORS.get(room_type, Color.WHITE)


static func category(room_type: int) -> String:
	if room_type == RoomType.START:
		return "start"
	if room_type == RoomType.MIDDLE_BOSS or room_type == RoomType.FINAL_BOSS:
		return "boss"
	if room_type == RoomType.BATTLE or room_type == RoomType.ELITE:
		return "combat"
	if room_type == RoomType.SHOP or room_type == RoomType.REST or room_type == RoomType.TREASURE:
		return "utility"
	return "event"


static func is_boss(room_type: int) -> bool:
	return room_type == RoomType.MIDDLE_BOSS or room_type == RoomType.FINAL_BOSS


static func is_regular(room_type: int) -> bool:
	return room_type in REGULAR_TYPES


static func is_safe(room_type: int) -> bool:
	return room_type == RoomType.SHOP or room_type == RoomType.REST or room_type == RoomType.TREASURE
