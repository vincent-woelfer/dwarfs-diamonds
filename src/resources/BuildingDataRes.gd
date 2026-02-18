@tool
class_name BuildingDataRes
extends Resource


########################################################################################################################
# Building Properties
# -> manually add new ones in instantiate_building_data
########################################################################################################################
@export_group("Building Properties")

## Name of the building. Must match the scene name of the building
@export var name: String

## Build time in seconds (without modifiers)
@export var build_time: float

########################################################################################################################
# Grid Patterns
########################################################################################################################
@export_group("Grid Patterns")

## Pattern defining the area the building occupies. Must be free (not solid, no other buildings) to place the building
@export var pattern_building: GridPatternRes
@export_custom(PROPERTY_HINT_COLOR_NO_ALPHA, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY)
var pattern_building_color: Color = Color.BLUE

## Pattern defining where the building can be built from (where dwarfs stand to build it)
@export var pattern_build_from: GridPatternRes
@export_custom(PROPERTY_HINT_COLOR_NO_ALPHA, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY)
var pattern_build_from_color: Color = Color.GREEN

## Pattern defining where the building requires solid ground
@export var pattern_solid_ground: GridPatternRes
@export_custom(PROPERTY_HINT_COLOR_NO_ALPHA, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY)
var pattern_solid_ground_color: Color = Color(0.3, 0.15, 0.1) # Dark brown

########################################################################################################################
# Action Points
########################################################################################################################
@export_group("Action Points")

## Action points associated with this building
@export var action_points: Array[ActionPointRes]

########################################################################################################################
# Placement Checks
########################################################################################################################
func is_placeable_at(grid_pos: Vector2i) -> bool:
	# Check if all building pattern cells exist, are free and have solid ground if required
	assert(pattern_building != null)
	var pattern_building_world := GridPatternRes.new(self.pattern_building.cells, grid_pos)

	for pos in pattern_building_world.get_world_positions():
		var cell: Cell = Global.level.get_cell(pos)
		if cell == null:
			return false

		# Cell for building must be empty
		if cell.is_solid:
			return false

		# Check if any other building occupies the cell
		# TODO could be improved by checking building types etc. Some buildings might be allowed to overlap others (maybe?)
		if not cell.buildings.is_empty():
			return false
				
	# Check solid ground requirement
	if pattern_solid_ground != null:
		var pattern_solid_ground_world := GridPatternRes.new(self.pattern_solid_ground.cells, grid_pos)

		for pos in pattern_solid_ground_world.get_world_positions():
			var cell: Cell = Global.level.get_cell(pos)
			if cell == null or not cell.is_solid:
				return false

	# TODO Maybe check if pattern_build_from are free?

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
		push_error("BuildingDataRes: Could not load scene at path: %s" % path)
		return null

	if res is not PackedScene:
		push_error("BuildingDataRes: Resource at path %s is not a PackedScene." % path)
		return null

	return (res as PackedScene).instantiate()


## Instantiate copy of building data, instantiates all grid-patterns at given grid position
func instantiate_building_data(grid_pos: Vector2i) -> BuildingDataRes:
	# Copy building data itself
	var instance: BuildingDataRes = BuildingDataRes.new()

	# Copy properties - TODO add new properties here
	instance.name = self.name
	instance.build_time = self.build_time

	instance.action_points = self.action_points.duplicate()

	# Find all pattern properties dynamically and instantiate them at the given position
	for property: Dictionary in self.get_property_list():
		var prop_name: String = property.name
		if prop_name.begins_with("pattern_") and property.type != TYPE_COLOR:
			var pattern: GridPatternRes = self.get(prop_name)
			instance.set(prop_name, _instantiate_pattern_at(pattern, grid_pos, prop_name))

	return instance


func _instantiate_pattern_at(pattern: GridPatternRes, grid_pos: Vector2i, var_name: String) -> GridPatternRes:
	if pattern == null:
		push_error("BuildingDataRes %s has no '%s' defined." % [ self.name, var_name])
		return GridPatternRes.new([], grid_pos)

	return GridPatternRes.new(pattern.cells, grid_pos)


## Returns an array of dictionaries with keys "pattern" (GridPatternRes) and "color" (Color), scanned dynamically from this BuildingDataRes.
## Used only for GridPatternVisualization
func get_all_patterns_with_colors() -> Array[Dictionary]:
	var patterns_with_colors: Array[Dictionary] = []

	# Find all pattern properties dynamically
	for property: Dictionary in self.get_property_list():
		var prop_name: String = property.name
		if prop_name.begins_with("pattern_") and property.type != TYPE_COLOR:
			var pattern: GridPatternRes = self.get(prop_name)
			var color: Color = self.get("%s_color" % prop_name)
			patterns_with_colors.append({"pattern": pattern, "color": color})

	return patterns_with_colors


########################################################################################################################
# Validation
########################################################################################################################
func _validate_property(property: Dictionary) -> void:
	var prop_name: String = property.name
	var prop_variant: Variant = self.get(prop_name)

	# Validate GridPatternRes properties
	if prop_name.begins_with("pattern_") and prop_variant is GridPatternRes:
		var prop_pattern: GridPatternRes = prop_variant

		if prop_pattern == null:
			push_warning("BuildingDataRes: '%s' is not set for building '%s'." % [property.name, name])
			return

		# Empty patterns are a warning, depending on which pattern it is. Check manually here.
		var patterns_should_not_be_empty := ["pattern_building", "pattern_build_from"]
		if prop_pattern.cells.is_empty():
			if prop_name in patterns_should_not_be_empty:
				push_warning("BuildingDataRes: '%s' has an empty pattern for building '%s'." % [property.name, name])
