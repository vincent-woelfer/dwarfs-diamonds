@tool
class_name BuildingDataRes
extends Resource


########################################################################################################################
# Building Properties
# -> manually add new ones in instantiate_building_data
########################################################################################################################
@export_group("Building Type")
## BuildingType of the building
@export var type: Enum.BuildingType


@export_group("Building Properties")
## Visual / UI Name, must never affect gameplay / logic!!!
@export var name: String

## Build time in seconds (without modifiers)
@export_range(0.0, 20.0, 0.01, "or_greater", "suffix:s")
var build_time: float = 1.0


## Required materials to build this building.
@export var required_materials: ItemTypeList = ItemTypeList.new()

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
# DEV Functions
########################################################################################################################
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
