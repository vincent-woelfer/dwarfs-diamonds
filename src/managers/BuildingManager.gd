class_name BuildingManager
extends Node2D

var buildings: Array[Building] = []
var action_points: Array[ActionPoint] = []

# Array[Array[Vector2i]] - For each building type, a list of all cells where it can be placed
var placement_checks: Array[Array] = []


func _process(delta: float) -> void:
	update_all_placement_checks()


func update_all_placement_checks() -> void:
	var start_time := Time.get_ticks_msec()

	placement_checks.clear()

	for building_type: Enum.BuildingType in Enum.BuildingType.values():
		var building_data: BuildingDataRes = Util.get_building_data(building_type)

		var cells: Array[Vector2i] = []

		for x in range(Global.LEVEL_WIDTH):
			for y in range(Global.LEVEL_HEIGHT):
				var grid_pos: Vector2i = Vector2i(x, y)
				if PlacementChecks.is_placeable_at(building_data, grid_pos):
					cells.append(grid_pos)

		cells.append(Vector2i(20, 20))
		cells.append(Vector2i(20, 21))
		cells.append(Vector2i(20, 22))
		cells.append(Vector2i(20, 23))

		# Append
		placement_checks.append(cells)

	var duration := Time.get_ticks_msec() - start_time
	# HexLog.print("Buildings => Updated %d building placement checks in: %d ms" % [Enum.BuildingType.size(), duration], Colors.GENERIC_INFO_PRINT_COLOR)


########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
###################################
# REGISTRATION
###################################
## Called by Building to register itself when created
func register_building(building: Building) -> void:
	if building in buildings:
		push_error("BuildingManager: Trying to register building that is already registered: %s" % building)
		return

	buildings.append(building)
	add_child(building)


## Called by Building to unregister itself when removed
func unregister_building(building: Building) -> void:
	if not building in buildings:
		push_error("BuildingManager: Trying to remove building that is not registered: %s" % building)
		return

	_unregister_action_points(building)
	buildings.erase(building)
	

## Called by building itself to finally be removes from scene
func remove_building(building: Building) -> void:
	if building == null:
		return
		
	remove_child(building)
	building.queue_free()


## Called by Building to register its action points when construction is complete
func register_action_points(building: Building) -> void:
	if not building in buildings:
		push_error("BuildingManager: Trying to add action points for building that is not registered: %s" % building)
		return

	for ap: ActionPoint in building.action_points:
		if ap in action_points:
			push_error("BuildingManager: Trying to register action point that is already registered: %s" % ap)
			continue

		action_points.append(ap)

		# Add to cell
		var cell: Cell = Global.level.get_cell(ap.grid_pos)
		if cell != null:
			cell.add_action_point(ap)


###################################
# Fetching Data
###################################
func get_all_action_points(type: ActionPoint.ActionType) -> Array[ActionPoint]:
	var filtered_aps: Array[ActionPoint] = []
	for ap: ActionPoint in action_points:
		# Check type
		if ap.type != type:
			continue

		# Check if active
		if not ap.is_active:
			continue

		# Verify that the cell is enabled in nav-mesh
		var cell: Cell = Global.level.get_cell(ap.grid_pos)
		if cell == null or not Global.level.nav_manager.is_cell_enabled(ap.grid_pos):
			continue

		# Finally add
		filtered_aps.append(ap)

	return filtered_aps

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
## Only called from unregister_building()
func _unregister_action_points(building: Building) -> void:
	for ap: ActionPoint in building.action_points:
		if ap not in action_points:
			push_error("BuildingManager: Trying to unregister action point that is not registered: %s" % ap)
			continue

		action_points.erase(ap)

		# Remove from cell
		var cell: Cell = Global.level.get_cell(ap.grid_pos)
		if cell != null:
			cell.remove_action_point(ap)
