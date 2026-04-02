class_name CellBuildingsContainer
extends RefCounted

########################################################################################################################
# External API for queries
########################################################################################################################
# Has ladder = has a complete ladder building
var _has_ladder: bool

# Blocked = has a non-complete platform blocking building
var _is_blocked: bool


# Public getters for flags
func has_ladder() -> bool:
    return _has_ladder

func is_blocked() -> bool:
    return _is_blocked

########################################################################################################################
# Main storage and logic
########################################################################################################################
func add(building: BuildingBase) -> bool:
    if building in _buildings:
        return false
    _buildings.append(building)
    _update_flags()
    return true


func remove(building: BuildingBase) -> bool:
    if building not in _buildings:
        return false
    _buildings.erase(building)
    _update_flags()
    return true

func is_empty() -> bool:
    return _buildings.is_empty()

func get_buildings() -> Array[BuildingBase]:
    return _buildings

func has_this_specific_building(building: BuildingBase) -> bool:
    return building in _buildings

########################################################################################################################
# Internal Logic
########################################################################################################################
var _buildings: Array[BuildingBase] = []

func _init() -> void:
    _buildings = []
    _update_flags()

func _update_flags() -> void:
    # _has_ladder
    _has_ladder = false
    for building in _buildings:
        if building.building_data.type == BuildingDataRes.Type.LADDER and building.is_complete:
            _has_ladder = true

    # _is_blocked
    _is_blocked = false
    for building in _buildings:
        if building.building_data.type == BuildingDataRes.Type.PLATFORM_BLOCKING and not building.is_complete:
            _is_blocked = true
