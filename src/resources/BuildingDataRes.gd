@tool
class_name BuildingDataRes
extends Resource

########################################################################################################################
# ENUM DEFINITIONS BUILDING TYPES
########################################################################################################################
enum Type {
	INVALID,
	LADDER,
	OUTPOST,
	PLATFORM_BLOCKING,
	PLATFORM_BRIDGE,
}

const BUILDING_TYPE_NAMES: Dictionary[Type, String] = {
	Type.INVALID: "INVALID",
	Type.LADDER: "Ladder",
	Type.OUTPOST: "Outpost",
	Type.PLATFORM_BLOCKING: "PlatformBlocking",
	Type.PLATFORM_BRIDGE: "PlatformBridge",
}

########################################################################################################################
# Building Properties
# -> manually add new ones in instantiate_building_data
########################################################################################################################
@export_group("Building Properties")

## Type of the building, determines name aswell.
@export var type: Type

## Build time in seconds (without modifiers)
@export_range(0.0, 20.0, 0.01, "or_greater", "suffix:s")
var build_time: float = 1.0


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

## Patter defining where the building blocks movement, e.g. for platforms. Relevant for placement checks aswell (no dwarf must be in blocking area when placing the building).
@export var pattern_blocking: GridPatternRes
@export_custom(PROPERTY_HINT_COLOR_NO_ALPHA, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY)
var pattern_blocking_color: Color = Color.ORANGE_RED

########################################################################################################################
# Action Points
########################################################################################################################
@export_group("Action Points")

## Action points associated with this building
@export var action_points: Array[ActionPointRes]

########################################################################################################################
# Placement Checks
########################################################################################################################
## Main placing check, includes all the others
func is_placeable_at(building_grid_pos: Vector2i) -> bool:
	if not is_building_pattern_clear(building_grid_pos):
		return false
				
	if not has_solid_ground_at(building_grid_pos):
		return false

	if not has_valid_build_from_cell(building_grid_pos):
		return false
	
	if not is_blocking_pattern_clear_at(building_grid_pos):
		return false

	# Additional custom checks - for now hardcoded here.
	# TODO override has_solid_ground check in child class
	if self.type == Type.LADDER:
		if not Ladder.is_placement_valid_for_ladder(building_grid_pos):
			return false
	elif self.type == Type.PLATFORM_BRIDGE:
		if not PlatformBridge.is_placement_valid_for_platform_bridge(building_grid_pos):
			return false

	return true


func is_building_pattern_clear(building_grid_pos: Vector2i) -> bool:
	# Check if all building pattern cells exist, are free and have solid ground if required
	assert(pattern_building != null)

	# Check building pattern cells
	var pattern_building_world := GridPatternRes.init_from_pattern(self.pattern_building, building_grid_pos)
	for pos in pattern_building_world.get_world_positions():
		var cell: Cell = Global.level.get_cell(pos)
		if cell == null:
			return false

		# Cell for building must be empty
		if cell.is_solid or cell.buildings.is_blocked():
			return false

		# Check if any other building occupies the cell
		# TODO could be improved by checking building types etc. Some buildings might be allowed to overlap others (maybe?)
		if not cell.buildings.is_empty():
			return false
		
	return true

## Build from does not need validation, player is required to place it correctly.
## Only validation is that at least once cell must exists (no map border).
func has_valid_build_from_cell(building_grid_pos: Vector2i) -> bool:
	var pattern_build_from_world := GridPatternRes.init_from_pattern(self.pattern_build_from, building_grid_pos)
	var at_least_one_build_from_cell_exists := false
	for pos in pattern_build_from_world.get_world_positions():
		var cell: Cell = Global.level.get_cell(pos)
		if cell == null:
			continue
		at_least_one_build_from_cell_exists = true
		break
	return at_least_one_build_from_cell_exists

func has_solid_ground_at(building_grid_pos: Vector2i) -> bool:
	if pattern_solid_ground == null:
		return true

	var pattern_solid_ground_world := GridPatternRes.init_from_pattern(self.pattern_solid_ground, building_grid_pos)

	# Check solid ground requirement
	for pos in pattern_solid_ground_world.get_world_positions():
		var cell: Cell = Global.level.get_cell(pos)
		if not (cell != null and cell.is_solid_ground()):
			return false

	return true


func is_blocking_pattern_clear_at(building_grid_pos: Vector2i) -> bool:
	if pattern_blocking == null:
		return true
		
	var pattern_blocking_world := GridPatternRes.init_from_pattern(self.pattern_blocking, building_grid_pos)

	# Check blocking pattern
	for pos in pattern_blocking_world.get_world_positions():
		var cell: Cell = Global.level.get_cell(pos)
		if cell == null:
			continue

		# If any dwarf is in the blocking area, it's not clear
		var dwarfs_in_cell: Array[Dwarf] = Global.level.get_dwarfs_in_cell(pos)
		if not dwarfs_in_cell.is_empty():
			return false

	return true

########################################################################################################################
# Utility functions
########################################################################################################################
func name() -> String:
	return BUILDING_TYPE_NAMES.get(type, "Unknown")


########################################################################################################################
# Scene Instantiation
########################################################################################################################
func instantiate_scene() -> Node2D:
	return _load_scene_internal("res://scenes/buildings/%s.tscn" % name())

func instantiate_preview_scene() -> Node2D:
	return _load_scene_internal("res://scenes/buildings/%sPreview.tscn" % name())

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
	instance.type = self.type
	instance.build_time = self.build_time

	instance.action_points = self.action_points.duplicate()

	# Find all pattern properties dynamically and instantiate them at the given position
	for property: Dictionary in self.get_property_list():
		var prop_name: String = property.name
		if prop_name.begins_with("pattern_") and property.type != TYPE_COLOR:
			var pattern: GridPatternRes = self.get(prop_name)
			instance.set(prop_name, GridPatternRes.init_from_pattern(pattern, grid_pos))

	# TODO remove instancing completely, building data is static and does not change. Rework pattern instantiation

	return instance


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

	# Validate that type is set to a valid value
	if prop_name == "type" and prop_variant is Type:
		var prop_type: Type = prop_variant
		if prop_type == Type.INVALID:
			push_warning("BuildingDataRes: Invalid building type '%s' for building '%s'." % [Enum.to_str(Type, prop_type), name()])

	# Validate GridPatternRes properties
	if prop_name.begins_with("pattern_") and prop_variant is GridPatternRes:
		var prop_pattern: GridPatternRes = prop_variant

		if prop_pattern == null:
			push_warning("BuildingDataRes: '%s' is not set for building '%s'." % [property.name, name()])
			return

		# Empty patterns are a warning, depending on which pattern it is. Check manually here.
		var patterns_should_not_be_empty := ["pattern_building", "pattern_build_from"]
		if prop_pattern.cells.is_empty():
			if prop_name in patterns_should_not_be_empty:
				push_warning("BuildingDataRes: '%s' has an empty pattern for building '%s'." % [property.name, name()])
