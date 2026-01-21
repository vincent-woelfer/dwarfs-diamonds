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


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
