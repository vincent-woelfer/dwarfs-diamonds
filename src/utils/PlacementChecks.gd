@tool
class_name PlacementChecks


########################################################################################################################
# Placement Checks
########################################################################################################################
## Main placing check, includes all the others
static func is_placeable_at(building_data: BuildingDataRes, grid_pos: Vector2i) -> bool:
	if not is_building_pattern_clear(building_data, grid_pos):
		return false
				
	if not has_solid_ground_at(building_data, grid_pos):
		return false

	if not has_valid_build_from_cell(building_data, grid_pos):
		return false
	
	# Additional custom checks - for now hardcoded here.
	# TODO override has_solid_ground check in child class
	if building_data.type == Enum.BuildingType.LADDER:
		if not Ladder.is_placement_valid_for_ladder(grid_pos):
			return false
	elif building_data.type == Enum.BuildingType.PLATFORM_BRIDGE:
		if not PlatformBridge.is_placement_valid_for_platform_bridge(grid_pos):
			return false

	return true


## Check if all building pattern cells exist, are free and have solid ground if required
static func is_building_pattern_clear(building_data: BuildingDataRes, grid_pos: Vector2i) -> bool:
	assert(building_data.pattern_building != null)

	# Check building pattern cells
	for pos: Vector2i in building_data.pattern_building.get_positions(grid_pos):
		var cell: Cell = Global.level.get_cell(pos)
		if cell == null:
			return false

		# Cell for building must be empty
		if cell.is_solid or cell.buildings.is_blocked():
			return false

		# Check if any other building occupies the cell
		# TODO could be improved by checking building types etc. Some buildings might be allowed to overlap others (maybe?)
		if not cell.get_buildings().is_empty():
			return false
		
	return true


## Build from does not need validation, player is required to place it correctly.
## Only validation is that at least once cell must exists (no map border).
static func has_valid_build_from_cell(building_data: BuildingDataRes, grid_pos: Vector2i) -> bool:
	assert(building_data.pattern_build_from != null)

	var at_least_one_build_from_cell_exists := not building_data.pattern_build_from.get_positions(grid_pos).is_empty()
	return at_least_one_build_from_cell_exists


static func has_solid_ground_at(building_data: BuildingDataRes, grid_pos: Vector2i) -> bool:
	if building_data.pattern_solid_ground == null:
		return true

	# Check solid ground requirement
	for pos: Vector2i in building_data.pattern_solid_ground.get_positions(grid_pos):
		var cell: Cell = Global.level.get_cell(pos)
		if not (cell != null and cell.is_solid_ground()):
			return false

	return true
