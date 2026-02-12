class_name BuildingManager
extends Node2D

var buildings: Array[BuildingBase] = []

var action_points: Array[ActionPoint] = []

########################################################################################################################
# ALL BUILDING DATA PRELOADS
########################################################################################################################
static var ladder_building_data: BuildingDataRes = preload("res://scenes/buildings/LadderBuildingData.tres") as BuildingDataRes
static var outpost_building_data: BuildingDataRes = preload("res://scenes/buildings/OutpostBuildingData.tres") as BuildingDataRes

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################

###################################
# REGISTRATION
###################################
## Called by BuildingBase to register itself when created
func register_building(building: BuildingBase) -> void:
	if building in buildings:
		push_error("BuildingManager: Trying to register building that is already registered: %s" % building)
		return

	buildings.append(building)
	add_child(building)


## Called by BuildingBase to unregister itself when removed
func remove_building(building: BuildingBase) -> void:
	if not building in buildings:
		push_error("BuildingManager: Trying to remove building that is not registered: %s" % building)
		return

	_unregister_action_points(building)

	buildings.erase(building)
	remove_child(building)
	building.queue_free()


## Called by BuildingBase to register its action points when construction is complete
func register_action_points(building: BuildingBase) -> void:
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
## Only called from remove_building()
func _unregister_action_points(building: BuildingBase) -> void:
	for ap: ActionPoint in building.action_points:
		if ap not in action_points:
			push_error("BuildingManager: Trying to unregister action point that is not registered: %s" % ap)
			continue

		action_points.erase(ap)

		# Remove from cell
		var cell: Cell = Global.level.get_cell(ap.grid_pos)
		if cell != null:
			cell.remove_action_point(ap)
