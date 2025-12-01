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
	

static func to_print_color(color: Color) -> Color:
	return color.lightened(0.5)


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


########################################################################################################################
# DWARF COLORS
########################################################################################################################
static func get_rand_dwarf_color(dwarf_id: int) -> Color:
	# Shuffle each time the game is started to get different color assignments
	if dwarf_id == 0:
		dwarf_colors.shuffle()

	# Deterministic based on dwarf_id
	var index := dwarf_id % dwarf_colors.size()
	return dwarf_colors[index]

static var dwarf_colors := [
	Color8(250, 0, 0), # Red
	Color8(0, 250, 0), # Green
	Color8(0, 0, 250), # Blue
	Color8(255, 215, 0), # Gold
	Color8(140, 0, 140), # Purple
]

########################################################################################################################
# CELL COLORS
########################################################################################################################
static func get_cell_color(type: Enum.CellType, solid: bool) -> Color:
	return CellTypeColor.get(type, FALLBACK_COLOR)

static var CellTypeColor := {
	Enum.CellType.A: Color8(81, 73, 106), # Deep violet-blue tone
	Enum.CellType.B: Color8(106, 73, 73), # Muted red-brown tone
	Enum.CellType.C: Color8(76, 96, 71), # Olive
	Enum.CellType.BUILDING: Color8(121, 96, 76), # Warm orange-brown
	Enum.CellType.SKY: Color(0.44, 0.76, 0.96), # Sky blue
}

########################################################################################################################
# GRID PATTERN COLORS
########################################################################################################################
## GridPattern Colors. RGB are used in BuildingData, use others here
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
# BUILDING COLORS
########################################################################################################################
static var building_modulate_finished: Color = Color(1, 1, 1, 1.0)
# static var building_modulate_unfinished: Color = Color(1.0, 0.75, 0.3, 1.0) # Slightly orange tint
static var building_modulate_unfinished: Color = Color(1.2, 0.2, 0.2, 0.8) # red tint
static var building_light_mask_finished: int = 1
static var building_light_mask_unfinished: int = 0
