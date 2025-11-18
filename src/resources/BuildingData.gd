@tool
class_name BuildingData
extends Resource


@export var name: String
@export var build_time: float
@export var scene: PackedScene

# Grid Patterns
@export var grid_pattern_building: GridPattern
const grid_pattern_building_color: Color = Color.BLUE

@export var grid_pattern_build_from: GridPattern
const grid_pattern_build_from_color: Color = Color.GREEN


func get_all_patterns_with_colors() -> Array[Dictionary]:
    var patterns_with_colors: Array[Dictionary] = []

    patterns_with_colors.append({
        "pattern": grid_pattern_building,
        "color": grid_pattern_building_color
    })
    patterns_with_colors.append({
        "pattern": grid_pattern_build_from,
        "color": grid_pattern_build_from_color
    })

    return patterns_with_colors
