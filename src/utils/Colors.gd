class_name Colors

static var DEFAULT: Color = Color(1.0, 0.0, 1.0) # Magenta, indicates error

static func rand_color() -> Color:
	return Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8), 1.0)


static func rand_rubble_color() -> Color:
	return Color(randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 1.0), 1.0)
	

static func get_cell_color(type: Enum.CellType, solid: bool) -> Color:
	var color: Color = CellTypeColor.get(type, DEFAULT)

	# Not here, done in shader
	# if solid:
		# color = color.darkened(0.3)

	return color.lightened(0.2)


static var dwarf_colors := [
	Color8(250, 0, 0), # Red
	Color8(0, 250, 0), # Green
	Color8(0, 0, 250), # Blue
	Color8(255, 215, 0), # Gold
	Color8(128, 0, 128), # Purple
]
static func get_rand_dwarf_color(dwarf_id: int) -> Color:
	# Shuffle each time the game is started to get different color assignments
	if dwarf_id == 0:
		dwarf_colors.shuffle()

	# Deterministic based on dwarf_id
	var index := dwarf_id % dwarf_colors.size()
	return dwarf_colors[index]

static func to_print_color(color: Color) -> Color:
	return color.lightened(0.5)


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


static var CellTypeColor := {
	Enum.CellType.A: Color8(45, 36, 70), # Deep violet-blue tone
	Enum.CellType.B: Color8(70, 36, 36), # Muted red-brown tone
	Enum.CellType.C: Color8(40, 60, 35), # Olive
	Enum.CellType.BUILDING: Color8(85, 60, 40), # Warm orange-brown
	Enum.CellType.SKY: Color(0.3, 0.7, 0.95), # Avoit 1.0 in any channel
}
