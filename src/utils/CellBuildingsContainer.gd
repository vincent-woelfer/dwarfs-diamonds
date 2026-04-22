class_name CellBuildingsContainer
extends RefCounted

########################################################################################################################
# External API for queries
########################################################################################################################
# Has ladder = has a complete ladder building
func has_ladder() -> bool:
    var _has_ladder := false
    for building in _buildings:
        if building.building_data.type == Enum.BuildingType.LADDER and building.is_complete:
            _has_ladder = true

    return _has_ladder

# Blocked = has a blocking platform building (doesnt matter if complete)
func is_blocked() -> bool:
    var _is_blocked := false
    for building in _buildings:
        if building.building_data.pattern_blocking.get_world_positions().has(_parent.grid_pos):
            _is_blocked = true
            break

    return _is_blocked

# Has platform = has a complete platform building
func has_platform() -> bool:
    var _has_platform := false
    for building in _buildings:
        if building.building_data.type in [Enum.BuildingType.PLATFORM_BLOCKING, Enum.BuildingType.PLATFORM_BRIDGE ] and building.is_complete:
            _has_platform = true
            
    return _has_platform

########################################################################################################################
# Main API
########################################################################################################################
func add(building: Building) -> bool:
    if building in _buildings:
        return false
    _buildings.append(building)
    return true


func remove(building: Building) -> bool:
    if building not in _buildings:
        return false
    _buildings.erase(building)
    return true

########################################################################################################################
# Additional Utility API
########################################################################################################################
func is_empty() -> bool:
    return _buildings.is_empty()

func get_buildings() -> Array[Building]:
    return _buildings

func has_this_specific_building(building: Building) -> bool:
    return building in _buildings

# TODO improve per platform type
func get_platform_mining_hardness() -> float:
    for building in _buildings:
        if building.building_data.type == Enum.BuildingType.PLATFORM_BLOCKING and building.is_complete:
            return 3.0
    return 1.0

########################################################################################################################
# Internal Logic
########################################################################################################################
var _buildings: Array[Building] = []
var _parent: Cell

func _init(_parent_cell: Cell) -> void:
    _buildings = []
    _parent = _parent_cell

func _update_flags() -> void:
    return
#     # _has_ladder
#     _has_ladder = false
#     for building in _buildings:
#         if building.building_data.type == BuildingDataRes.Type.LADDER and building.is_complete:
#             _has_ladder = true

#     # _is_blocked
#     _is_blocked = false
#     for building in _buildings:
#         if building.building_data.type == BuildingDataRes.Type.PLATFORM_BLOCKING:
#             _is_blocked = true

#     # _has_platform
#     _has_platform = false
#     for building in _buildings:
#         if building.building_data.type == BuildingDataRes.Type.PLATFORM_BLOCKING and building.is_complete:
#             _has_platform = true
#             print("CellBuildingsContainer %s: has complete platform", building.grid_pos)
