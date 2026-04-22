@tool # because Building is @tool
class_name Ladder
extends Building


## Ladders cant be placed "in the sky" -> under ground or adjacent to at least one solid ground cell
static func is_placement_valid_for_ladder(building_grid_pos: Vector2i) -> bool:
	var cell: Cell = Global.level.get_cell(building_grid_pos)
	if cell == null:
		return false

	# Under ground is always fine
	if not Global.level.is_sky(building_grid_pos):
		return true

	# Sky -> check neighbours
	var at_least_one_solid_neighbour := false
	for dir: Vector2i in Util.neighbours_cardinal:
		var n_cell: Cell = Global.level.get_cell(building_grid_pos + dir)
		if n_cell == null:
			continue

		if n_cell.is_solid_ground():
			at_least_one_solid_neighbour = true
			break

	return at_least_one_solid_neighbour
