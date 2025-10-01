@tool
class_name Colors

static func rand_color() -> Color:
	return Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8), 1.0)
	# return Color(randf(), randf(), randf(), 1.0)


static func get_cell_color(type: Cell.CellType, solid: bool) -> Color:
	match type:
		Cell.CellType.A:
			return COLOR_A
		Cell.CellType.B:
			return COLOR_B
		Cell.CellType.C:
			return COLOR_C

	assert(false, "Unknown CellType")
	return Color.WHITE


static var COLOR_A: Color = Color8(42, 36, 48)
static var COLOR_B: Color = Color8(58, 36, 38)
static var COLOR_C: Color = Color8(46, 38, 31)
