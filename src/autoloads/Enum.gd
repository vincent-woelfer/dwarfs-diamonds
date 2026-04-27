# No class_name here, the name of the singleton is set in the autoload
@tool
extends Node

# Functions not static since this is an autoload and "Enum" is its global name

## Given the Enum Class, convert enum value (int) to string name (contained in Enum Class)
func to_str(enum_dict: Dictionary, value: int) -> String:
	for n: String in enum_dict:
		if enum_dict[n] == value:
			return n
	return "Unknown"

## Given the Enum Class, return an array of all enum entries as string
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
	SKY
}

enum ProcessPriority {
	DEFAULT = 0,
	NAV = 1,
	JOBS = 2,
	CELL = 5,
	# Process accumulated signals
	EVENT_BUS = 10,
	# Last Phase: Visuals
	CELL_VISUAL = 11
}

enum ZIndex {
	CELL_SKY = -10,
	CELL_SOLID = 0,	
	DECO = 50,
	BUILDINGS = 100,
	DWARFS = 200,
	RUBBLE = 250,
	GEMSTONE = 251,
	GRID_PATTERN_VISUALIZATION = 300,
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

########################################################################################################################
# ENUM DEFINITIONS BUILDING TYPES
########################################################################################################################
enum BuildingType {
	LADDER,
	OUTPOST,
	PLATFORM_BLOCKING,
	PLATFORM_BRIDGE,
}

