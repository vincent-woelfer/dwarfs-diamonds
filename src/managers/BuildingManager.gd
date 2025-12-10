class_name BuildingManager
extends Node2D

var buildings: Array[BuildingBase] = []

########################################################################################################################
# ALL BUILDING DATA PRELOADS
########################################################################################################################
static var ladder_building_data: BuildingData = preload("res://scenes/buildings/LadderBuildingData.tres") as BuildingData
static var base_building_data: BuildingData = preload("res://scenes/buildings/BaseBuildingData.tres") as BuildingData

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func register_building(building: BuildingBase) -> void:
	if building in buildings:
		return

	buildings.append(building)
	add_child(building)


func remove_building(building: BuildingBase) -> void:
	if not building in buildings:
		return

	buildings.erase(building)
	remove_child(building)
	building.queue_free()


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
