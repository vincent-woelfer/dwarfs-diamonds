class_name BuildingManager
extends Node2D

var buildings: Array[BuildingBase] = []

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
