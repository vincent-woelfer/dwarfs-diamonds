# No class_name here, the name of the singleton is set in the autoload
@tool
extends Node

func to_str(enum_dict: Dictionary, value: int) -> String:
	for n: String in enum_dict:
		if enum_dict[n] == value:
			return n
	return "Unknown"

func to_string_array(enum_dict: Dictionary) -> Array[String]:
	var names: Array[String] = []
	for n: String in enum_dict:
		names.append(n)
	return names

# Type of cell
enum CellType {
	A,
	B,
	C,
	BUILDING,
	SKY
}

enum ProcessPriority {
	DEFAULT = 0,
	NAV = 1,
	JOBS = 2,
	CELL = 10,
	CELL_VISUAL = 11
}

enum ZIndex {
	CELL = 0,
	GRID_PATTERN_VISUALIZATION = 10,
	DECO = 50,
	BUILDINGS = 100,
	DWARFS = 200,
	RUBBLE = 250,
	GEMSTONE = 251,
	UI_MOUSE_POINTER = 1000,
}


# Index of poly points of cell
enum PolyPoint {
	TOP_LEFT = 0,
	TOP = 1,
	TOP_RIGHT = 2,
	RIGHT = 3,
	BOT_RIGHT = 4,
	BOT = 5,
	BOT_LEFT = 6,
	LEFT = 7,
}

# Movement Mode of path
enum MoveMode {
	WALK,	
	CLIMB_WALL_UP,
	CLIMB_WALL_DOWN,
	CLIMB_LADDER_UP,
	CLIMB_LADDER_DOWN,
	WALK_NO_FALLING_SPECIAL, # Used for pathfinding to ignore falling special case when walking (e.g. when already falling or climbing)
}

enum CarryableType {
	RUBBLE,
	GEMSTONE,
}
