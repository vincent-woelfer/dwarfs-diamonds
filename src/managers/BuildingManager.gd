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
func register_building(building: BuildingBase) -> void:
	if building in buildings:
		push_error("BuildingManager: Trying to register building that is already registered: %s" % building)
		return

	buildings.append(building)
	add_child(building)


func remove_building(building: BuildingBase) -> void:
	if not building in buildings:
		push_error("BuildingManager: Trying to remove building that is not registered: %s" % building)
		return

	# Remove action points associated with this building
	for ap: ActionPoint in building.action_points:
		action_points.erase(ap)

	buildings.erase(building)
	remove_child(building)
	building.queue_free()


func register_action_points(building: BuildingBase) -> void:
	if not building in buildings:
		push_error("BuildingManager: Trying to add action points for building that is not registered: %s" % building)
		return

	for ap: ActionPoint in building.action_points:
		if ap in action_points:
			push_error("BuildingManager: Trying to register action point that is already registered: %s" % ap)
			continue

		action_points.append(ap)

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

		# Verify that the cell is reachable in nav-mesh
		var cell: Cell = Global.level.get_cell(ap.grid_pos)
		if cell == null or not Global.level.nav_manager.is_cell_enabled(ap.grid_pos):
			continue

		# Finally add
		filtered_aps.append(ap)

	return filtered_aps

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
