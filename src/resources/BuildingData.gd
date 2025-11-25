@tool
class_name BuildingData
extends Resource


@export_group("Building Properties")
## Name of the building. Must match the scene name of the building
@export var name: String

## Build time in seconds (without modifiers)
@export var build_time: float

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

## Pattern defining where the building can be accessed from
@export var pattern_entrance: GridPattern
const pattern_entrance_color: Color = Color.RED

## Pattern defining where the building requires solid ground
@export var pattern_solid_ground: GridPattern
const pattern_solid_ground_color: Color = Color(0.3, 0.15, 0.1) # Dark brown

########################################################################################################################
# Placement Checks
########################################################################################################################
func is_placeable_at(grid_pos: Vector2i) -> bool:
	# Check if all building pattern cells exist, are free and have solid ground if required
	assert(pattern_building != null)
	var pattern_building_world := GridPattern.new(self.pattern_building.pattern, grid_pos)

	for pos in pattern_building_world.get_world_positions():
		var cell: Cell = Global.level.get_cell(pos)
		if cell == null:
			return false

		# Cell for building must be empty
		if cell.is_solid:
			return false

		# Check if any other building occupies the cell
		# TODO does this work for multi-cell buildings??? Decide wheter to add building to all cells or only central cell
		if not cell.buildings.is_empty():
			return false
				
	# Check solid ground requirement
	if pattern_solid_ground != null:
		var pattern_solid_ground_world := GridPattern.new(self.pattern_solid_ground.pattern, grid_pos)

		for pos in pattern_solid_ground_world.get_world_positions():
			var cell: Cell = Global.level.get_cell(pos)
			if cell == null:
				return false

			if not cell.is_solid:
				return false

	# TODO Check pattern_build_from conditions here if needed ???

	return true


########################################################################################################################
# Scene Instantiation
########################################################################################################################
func instantiate_scene() -> Node2D:
	return _load_scene_internal("res://scenes/buildings/%s.tscn" % name)

func instantiate_preview_scene() -> Node2D:
	return _load_scene_internal("res://scenes/buildings/%sPreview.tscn" % name)

func _load_scene_internal(path: String) -> Node2D:
	var res: Resource = load(path)
	if res == null:
		push_error("BuildingData: Could not load scene at path: %s" % path)
		return null

	if res is not PackedScene:
		push_error("BuildingData: Resource at path %s is not a PackedScene." % path)
		return null

	return (res as PackedScene).instantiate()


func instantiate_building_data(grid_pos: Vector2i) -> BuildingData:
	# Copy building data itself
	var instance: BuildingData = BuildingData.new()

	# Copy properties - TODO add new properties here
	instance.name = self.name
	instance.build_time = self.build_time

	# Adjust patterns to new position - find all patterns dynamically
	for property: Dictionary in self.get_property_list():
		var prop_name: String = property.name
		if prop_name.begins_with("pattern_") and property.type != TYPE_COLOR:
			@warning_ignore("UNSAFE_CAST")
			var self_pattern := self.get(prop_name) as GridPattern
			instance.set(prop_name, _instantiate_pattern_at(self_pattern, grid_pos, prop_name))

	return instance


func _instantiate_pattern_at(pattern: GridPattern, grid_pos: Vector2i, var_name: String) -> GridPattern:
	if pattern == null:
		push_error("BuildingData %s has no '%s' defined." % [self.name, var_name])
		return GridPattern.new([], grid_pos)

	return GridPattern.new(pattern.pattern, grid_pos)


func get_all_patterns_with_colors() -> Array[Dictionary]:
	var patterns_with_colors: Array[Dictionary] = []

	# Find all pattern properties dynamically
	for property: Dictionary in self.get_property_list():
		var prop_name: String = property.name
		if prop_name.begins_with("pattern_") and property.type != TYPE_COLOR:
			var pattern: GridPattern = self.get(prop_name)
			var color: Color = self.get("%s_color" % prop_name)
			patterns_with_colors.append({"pattern": pattern, "color": color})

	return patterns_with_colors


########################################################################################################################
# Validation
########################################################################################################################
func _validate_property(property: Dictionary) -> void:
	var prop_name: String = property.name
	var prop_variant: Variant = self.get(prop_name)

	if prop_name.begins_with("pattern_") and prop_variant is GridPattern:
		@warning_ignore("UNSAFE_CAST")
		var prop_pattern := prop_variant as GridPattern

		if prop_pattern == null:
			push_warning("BuildingData: '%s' is not set for building '%s'." % [property.name, name])

		# Empty patterns are okay for some patterns. Filter manually
		elif prop_pattern.pattern.is_empty():
			if prop_name in ["pattern_building", "pattern_build_from"]:
				push_warning("BuildingData: '%s' has an empty pattern for building '%s'." % [property.name, name])
