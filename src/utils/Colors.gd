class_name Colors

static func rand_color() -> Color:
	return Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8), 1.0)
	# return Color(randf(), randf(), randf(), 1.0)


static func get_cell_color(type: Enum.CellType, solid: bool) -> Color:
	var color: Color
	
	match type:
		Enum.CellType.A:
			color = COLOR_A
		Enum.CellType.B:
			color = COLOR_B
		Enum.CellType.C:
			color = COLOR_C
		Enum.CellType.BUILDING:
			color = COLOR_BUILDING
		Enum.CellType.SKY:
			color = COLOR_SKY
		_:
			assert(false, "Unknown CellType")
			color = Color.WHITE

	# Not here, done in shader
	# if solid:
		# color = color.darkened(0.3)

	return color.lightened(0.2)

	
static var COLOR_A: Color = Color8(45, 36, 70) # Deep violet-blue tone
static var COLOR_B: Color = Color8(70, 36, 36) # Muted red-brown tone
static var COLOR_C: Color = Color8(40, 60, 35) # Olive-green tone
static var COLOR_BUILDING: Color = Color8(85, 60, 40) # Warm orange-brown
static var COLOR_SKY: Color = Color(0.3, 0.7, 0.95) # Avoit 1.0 in any channel
