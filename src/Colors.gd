class_name Colors

static func rand_color() -> Color:
	return Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8), 1.0)
	# return Color(randf(), randf(), randf(), 1.0)


static func get_cell_color(type: Cell.CellType, solid: bool) -> Color:
	return Color.GREEN.lerp(rand_color(), 0.35)
	
	# if solid:
	# 	match type:
	# 		Cell.CellType.A:
	# 			return COLOR_A_solid
	# 		Cell.CellType.B:
	# 			return COLOR_B_solid
	# 		Cell.CellType.C:
	# 			return COLOR_C_solid
	# else:
	# 	match type:
	# 		Cell.CellType.A:
	# 			return COLOR_A_tunnel
	# 		Cell.CellType.B:
	# 			return COLOR_B_tunnel
	# 		Cell.CellType.C:
	# 			return COLOR_C_tunnel

	# return Color.WHITE


static var COLOR_A_solid: Color = Color.DARK_SLATE_GRAY.darkened(0.5).darkened(0.25)
static var COLOR_B_solid: Color = Color.SADDLE_BROWN.darkened(0.5).darkened(0.25)
static var COLOR_C_solid: Color = Color.DARK_RED.darkened(0.5).darkened(0.25)

static var COLOR_A_tunnel: Color = Color.DARK_SLATE_GRAY.darkened(0.5)
static var COLOR_B_tunnel: Color = Color.SADDLE_BROWN.darkened(0.5)
static var COLOR_C_tunnel: Color = Color.DARK_RED.darkened(0.5)
