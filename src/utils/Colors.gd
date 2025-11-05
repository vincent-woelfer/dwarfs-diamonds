class_name Colors

static var DEFAULT: Color = Color(1.0, 0.0, 1.0) # Magenta, indicates error

static func rand_color() -> Color:
	return Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8), 1.0)


static func get_cell_color(type: Enum.CellType, solid: bool) -> Color:
	var color: Color = CellTypeColor.get(type, DEFAULT)

	# Not here, done in shader
	# if solid:
		# color = color.darkened(0.3)

	return color.lightened(0.2)


static var dwarf_colors := [
	Color8(250, 50, 50), # Red
	Color8(50, 250, 50), # Green
	Color8(50, 50, 250), # Blue
	Color8(255, 215, 0), # Gold
	Color8(128, 0, 128), # Purple
]

static var dwarf_color_uses := {}
static func get_rand_dwarf_color() -> Color:
	# Initialize usage counts
	if dwarf_color_uses.is_empty():
		for color: Color in dwarf_colors:
			dwarf_color_uses[color] = 0

	# sort array by least used
	var sorted_colors := dwarf_colors.duplicate()
	sorted_colors.shuffle()
	sorted_colors.sort_custom(func(a: Color, b: Color) -> int:
		return dwarf_color_uses[a] - dwarf_color_uses[b]
	)

	var selected_color: Color = sorted_colors[0]
	dwarf_color_uses[selected_color] += 1
	return selected_color


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


static var CellTypeColor := {
	Enum.CellType.A: Color8(45, 36, 70), # Deep violet-blue tone
	Enum.CellType.B: Color8(70, 36, 36), # Muted red-brown tone
	Enum.CellType.C: Color8(40, 60, 35), # Olive
	Enum.CellType.BUILDING: Color8(85, 60, 40), # Warm orange-brown
	Enum.CellType.SKY: Color(0.3, 0.7, 0.95), # Avoit 1.0 in any channel
}
