class_name InteractionPoint
extends GridObject2D

###################################
# ENUM DEFINITIONS
###################################
enum ActionType {
	DISPOSE_RUBBLE,
}


###################################
# Variables
###################################
var is_active: bool = true

var type: ActionType

var in_cell_pos: Vector2 = Vector2.ZERO

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func setup_interaction_point(grid_pos_: Vector2i, type_: ActionType) -> void:
	super.setup(grid_pos_, Vector2.ZERO)
	self.type = type_


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _ready() -> void:
	pass


func _to_string() -> String:
	var print_color := Colors.to_print_color(building_color)
	return Util.color_string("%s @%s" % [building_data.name, grid_pos], print_color)
