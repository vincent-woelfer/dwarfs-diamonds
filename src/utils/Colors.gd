@tool
class_name Colors

## Magenta, indicates error
static var FALLBACK_COLOR: Color = Color(1.0, 0.0, 1.0)

########################################################################################################################
# COLOR UTILITIES
########################################################################################################################
static func rand_color() -> Color:
	return Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8), 1.0)


static func rand_rubble_color() -> Color:
	return Color(randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 1.0), 1.0)
	

## Returns a lighter version of the color for printing in console
static func to_print_color(color: Color) -> Color:
	return color.lightened(0.35)


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


########################################################################################################################
# DWARF COLORS
########################################################################################################################
static func get_rand_dwarf_color(dwarf_id: int) -> Color:
	# Shuffle each time the game is started to get different color assignments
	# if dwarf_id == 0:
		# dwarf_colors.shuffle()
	# Deterministic based on dwarf_id
	var index := dwarf_id % dwarf_colors.size()
	return dwarf_colors[index]

static var dwarf_colors := [
	Color8(140, 0, 140), # Purple
	Color8(255, 215, 0), # Gold
	Color8(250, 0, 0), # Red
	Color8(0, 250, 0), # Green
	Color8(0, 0, 250), # Blue
]

########################################################################################################################
# BUILDING COLORS
########################################################################################################################
static var building_id: int = 0
static func get_rand_building_color() -> Color:
	# Shuffle each time the game is started to get different color assignments
	# if building_id == 0:
		# building_colors.shuffle()
	# Deterministic based on building_id
	var index := building_id % building_colors.size()
	building_id += 1
	return building_colors[index]

static var building_colors := [
	Color8(250, 0, 0), # Red
	Color8(0, 250, 0), # Green
	Color8(0, 0, 250), # Blue
	Color8(255, 215, 0), # Gold
	Color8(140, 0, 140), # Purple
]

########################################################################################################################
# CELL COLORS
########################################################################################################################
static func get_cell_color(type: Enum.CellType) -> Color:
	return CellTypeColor.get(type, FALLBACK_COLOR)

static var CellTypeColor := {
	Enum.CellType.A: Color8(81, 73, 106), # Deep violet-blue tone
	Enum.CellType.B: Color8(106, 73, 73), # Muted red-brown tone
	Enum.CellType.C: Color8(76, 96, 71), # Olive
	Enum.CellType.PLATFORM: Color8(121, 96, 76), # Warm orange-brown
	Enum.CellType.SKY: Color(0.44, 0.76, 0.96), # Sky blue
}

########################################################################################################################
# GRID PATTERN COLORS
########################################################################################################################
## GridPatternRes Colors. RGB are used in BuildingDataRes, use others here
static var grid_pattern_preview_colors: Array[Color] = [
	Color8(255, 215, 0), # Gold
	Color8(140, 0, 140), # Purple
	Color8(0, 255, 255), # Cyan
]

static func get_rand_grid_pattern_color(id: int) -> Color:
	# Deterministic based on id
	var index := id % grid_pattern_preview_colors.size()
	return grid_pattern_preview_colors[index]


########################################################################################################################
# ACTION POINT COLORS
########################################################################################################################
static func get_action_point_color(type: ActionPoint.ActionType) -> Color:
	return ActionPointColor.get(type, FALLBACK_COLOR)

static var ActionPointColor := {
	ActionPoint.ActionType.DISPOSE_RUBBLE: Color.DARK_ORANGE,
}

########################################################################################################################
# BUILDING COLORS
########################################################################################################################
static var building_modulate_finished: Color = Color(1, 1, 1, 1.0)
static var building_modulate_unfinished: Color = Color(1.2, 0.2, 0.2, 0.8) # red tint
static var building_light_mask_finished: int = 1
static var building_light_mask_unfinished: int = 0

static var building_modulate_external_destroy: Color = Color(1.2, 0.0, 0.0, 1.0) # red


########################################################################################################################
# JOB COLORS
########################################################################################################################
static var JOB_COLOR_ARCHIVED: Color = Color.SLATE_BLUE.lerp(Color.BLUE, 0.5)
static var JOB_COLOR_BLOCKED: Color = Color.RED.lerp(Color.ORANGE_RED, 0.4)
static var JOB_COLOR_READY: Color = Color.GREEN_YELLOW
static var JOB_COLOR_DOING: Color = Color(0.0, 0.8, 0.0)


########################################################################################################################
# GLOBAL MISC COLORS
########################################################################################################################
static var GLOBAL_ACTION_PRINT_COLOR: Color = to_print_color(Color.MAGENTA)
static var NAV_IMPORTANT_PRINT_COLOR: Color = to_print_color(Color.RED)
static var NAV_UNIMPORTANT_PRINT_COLOR: Color = to_print_color(Color.RED.lerp(Color.GRAY, 0.8))
static var LIGHT_DEPTH_PRINT_COLOR: Color = to_print_color(Color.DARK_BLUE)
static var TASK_PRINT_COLOR: Color = to_print_color(Color.DARK_CYAN)
