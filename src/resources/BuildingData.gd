@tool
class_name BuildingData
extends Resource


@export_group("Building Properties")
## Name of the building. Must match the scene name of the building
@export var name: String

## Build time in seconds (without modifiers)
@export var build_time: float

## If all cells below the building must be solid ground
@export var requires_solid_ground: bool = false

########################################################################################################################
# Grid Patterns
########################################################################################################################
@export_group("Grid Patterns")

## Pattern defining the area the building occupies
@export var pattern_building: GridPattern
const pattern_building_color: Color = Color.BLUE

## Pattern defining where the building can be built from
@export var pattern_build_from: GridPattern
const pattern_build_from_color: Color = Color.GREEN


########################################################################################################################
# Placement Checks
########################################################################################################################
func is_placeable_at(grid_pos: Vector2i) -> bool:
	assert(pattern_building != null)
	# assert(pattern_build_from != null)

	var pattern_building_world := GridPattern.new(self.pattern_building.pattern, grid_pos)


	# Check if all building pattern cells exist, are free and have solid ground if required
	for pos in pattern_building_world.get_world_positions():
		var cell: Cell = Global.level.get_cell(pos)
		if cell == null:
			return false

		# Cell for building must be empty
		if cell.is_solid:
			return false

		# Check for solid ground requirement
		if requires_solid_ground:
			if not cell.has_solid_ground():
				return false

		# Check if any other building occupies the cell
		# TODO does this work for multi-cell buildings??? Decide wheter to add building to all cells or only central cell
		if not cell.buildings.is_empty():
			return false
				

	# TODO Check pattern_build_from conditions here if needed ???

	return true


########################################################################################################################
# Scene Instantiation
########################################################################################################################
func instantiate_scene() -> Node2D:
	var scene_path: String = "res://scenes/buildings/%s.tscn" % name
	var res: Resource = load(scene_path)
	if res == null:
		push_error("BuildingData.instantiate_scene: Could not load scene at path: %s" % scene_path)
		return null

	if res is not PackedScene:
		push_error("BuildingData.instantiate_scene: Resource at path %s is not a PackedScene." % scene_path)
		return null

	return (res as PackedScene).instantiate()

func instantiate_preview_scene() -> Node2D:
	var scene_path: String = "res://scenes/buildings/%sPreview.tscn" % name
	var res: Resource = load(scene_path)
	if res == null:
		push_error("BuildingData.instantiate_preview_scene: Could not load scene at path: %s" % scene_path)
		return null

	if res is not PackedScene:
		push_error("BuildingData.instantiate_preview_scene: Resource at path %s is not a PackedScene." % scene_path)
		return null

	return (res as PackedScene).instantiate()


func instantiate_building_data(grid_pos: Vector2i) -> BuildingData:
	# Copy building data itself
	var instance: BuildingData = BuildingData.new()

	# Copy properties - TODO add new properties here
	instance.name = self.name
	instance.build_time = self.build_time
	instance.requires_solid_ground = self.requires_solid_ground

	# Adjust patterns to new position
	if self.pattern_building:
		instance.pattern_building = GridPattern.new(self.pattern_building.pattern, grid_pos)
	else:
		instance.pattern_building = GridPattern.new([], grid_pos)
		push_error("BuildingData.instantiate_building_data: BuildingData %s has no pattern_building defined." % self.name)

	if self.pattern_build_from:
		instance.pattern_build_from = GridPattern.new(self.pattern_build_from.pattern, grid_pos)
	else:
		instance.pattern_build_from = GridPattern.new([], grid_pos)
		push_error("BuildingData.instantiate_building_data: BuildingData %s has no pattern_build_from defined." % self.name)

	return instance


func get_all_patterns_with_colors() -> Array[Dictionary]:
	var patterns_with_colors: Array[Dictionary] = []
	patterns_with_colors.append({"pattern": pattern_building, "color": pattern_building_color})
	patterns_with_colors.append({"pattern": pattern_build_from, "color": pattern_build_from_color})
	# TODO add more patterns here if needed

	return patterns_with_colors


########################################################################################################################
# Validation
########################################################################################################################
func _validate_property(property: Dictionary) -> void:
	if property.name == "pattern_building" and pattern_building == null:
		push_warning("BuildingData: 'pattern_building' is not set for building '%s'." % name)

	if property.name == "pattern_build_from" and pattern_build_from == null:
		push_warning("BuildingData: 'pattern_build_from' is not set for building '%s'." % name)
