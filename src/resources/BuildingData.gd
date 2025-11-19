@tool
class_name BuildingData
extends Resource


## Name of the building. Must match the scene name of the building
@export var name: String

## Build time in seconds (without modifiers)
@export var build_time: float

## If all cells below the building must be solid ground
@export var requires_solid_ground: bool = false

########################################################################################################################
# Grid Patterns
########################################################################################################################
## Pattern defining the area the building occupies
@export var pattern_building: GridPattern
const pattern_building_color: Color = Color.BLUE

## Pattern defining where the building can be built from
@export var pattern_build_from: GridPattern
const pattern_build_from_color: Color = Color.GREEN


func get_all_patterns_with_colors() -> Array[Dictionary]:
	var patterns_with_colors: Array[Dictionary] = []

	patterns_with_colors.append({
		"pattern": pattern_building,
		"color": pattern_building_color
	})
	patterns_with_colors.append({
		"pattern": pattern_build_from,
		"color": pattern_build_from_color
	})

	return patterns_with_colors


########################################################################################################################
# Scene Instantiation
########################################################################################################################
func instantiate_scene() -> Node:
	var scene_path: String = "res://scenes/buildings/%s.tscn" % name
	var res: Resource = load(scene_path)
	if res == null:
		push_error("BuildingData.instantiate_scene: Could not load scene at path: %s" % scene_path)
		return null

	if res is not PackedScene:
		push_error("BuildingData.instantiate_scene: Resource at path %s is not a PackedScene." % scene_path)
		return null

	return (res as PackedScene).instantiate()


func instantiate_at_position(grid_pos: Vector2i) -> BuildingData:
	# Copy building data itself
	var instance: BuildingData = BuildingData.new()

	# Copy properties
	instance.name = self.name
	instance.build_time = self.build_time
	instance.requires_solid_ground = self.requires_solid_ground

	# Adjust patterns to new position
	if self.pattern_building:
		instance.pattern_building = GridPattern.new(self.pattern_building.pattern, grid_pos)
	else:
		instance.pattern_building = GridPattern.new([], grid_pos)
		push_error("BuildingData.instantiate_at_position: BuildingData %s has no pattern_building defined." % self.name)

	if self.pattern_build_from:
		instance.pattern_build_from = GridPattern.new(self.pattern_build_from.pattern, grid_pos)
	else:
		instance.pattern_build_from = GridPattern.new([], grid_pos)
		push_error("BuildingData.instantiate_at_position: BuildingData %s has no pattern_build_from defined." % self.name)

	return instance
