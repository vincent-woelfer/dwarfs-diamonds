class_name Colors

static func rand_color() -> Color:
	return Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8), 1.0)
	# return Color(randf(), randf(), randf(), 1.0)


static func get_cell_color(type: Global.CellType, solid: bool) -> Color:
	var color: Color
	
	match type:
		Global.CellType.A:
			color = COLOR_A
		Global.CellType.B:
			color = COLOR_B
		Global.CellType.C:
			color = COLOR_C
		Global.CellType.BUILDING:
			color = COLOR_BUILDING
		Global.CellType.SKY:
			color = COLOR_SKY
		_:
			assert(false, "Unknown CellType")
			color = Color.WHITE

	# Not here, done in shader
	# if solid:
		# color = color.darkened(0.3)

	return color.lightened(0.2)

	
static var COLOR_A: Color = Color8(42, 36, 48)
static var COLOR_B: Color = Color8(58, 36, 38)
static var COLOR_C: Color = Color8(46, 38, 31)
static var COLOR_BUILDING: Color = Color.BURLYWOOD
static var COLOR_SKY: Color = Color(0.3, 0.7, 1.0)
