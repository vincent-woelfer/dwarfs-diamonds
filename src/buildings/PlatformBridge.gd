@tool # because BuildingBase is @tool
class_name PlatformBridge
extends BuildingBase


## PlatformBridge requires solid ground on either side or below but not on both
static func is_placement_valid_for_platform_bridge(building_grid_pos: Vector2i) -> bool:
	var cell: Cell = Global.level.get_cell(building_grid_pos)
	if cell == null:
		return false

	var at_least_one_solid_neighbour := false
	for dir: Vector2i in [Global.VEC_LEFT, Global.VEC_DOWN, Global.VEC_RIGHT]:
		var n_cell: Cell = Global.level.get_cell(building_grid_pos + dir)
		if n_cell == null:
			continue

        # Includes platforms
		if n_cell.is_solid_ground():
			at_least_one_solid_neighbour = true
			break

	return at_least_one_solid_neighbour

