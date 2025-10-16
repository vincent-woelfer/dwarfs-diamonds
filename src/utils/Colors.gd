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


static var CellTypeColor := {
	Enum.CellType.A: Color8(45, 36, 70), # Deep violet-blue tone
	Enum.CellType.B: Color8(70, 36, 36), # Muted red-brown tone
	Enum.CellType.C: Color8(40, 60, 35), # Olive
	Enum.CellType.BUILDING: Color8(85, 60, 40), # Warm orange-brown
	Enum.CellType.SKY: Color(0.3, 0.7, 0.95), # Avoit 1.0 in any channel
}
