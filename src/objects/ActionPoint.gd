class_name ActionPoint
extends GridObject2D

###################################
# ENUM DEFINITIONS
###################################
enum ActionType {
	DROPOFF_RUBBLE,
	DROPOFF_GEMSTONE,
}


###################################
# Variables
###################################
var is_active: bool = true

var type: ActionType

# Local pos inside the cell
var in_cell_pos: Vector2 = Global.CELL_SIZE_VEC_HALF


## TODO DEV
var storage: StockpileComponent = null


########################################################################################################################
# SETUP
########################################################################################################################
func setup_action_point(grid_pos_: Vector2i, type_: ActionType) -> void:
	setup_grid_object(grid_pos_, Vector2.ZERO)
	self.type = type_

	storage = StockpileComponent.new()
	add_child(storage)
	storage.position = Global.CELL_OFFSET_CORNER_TO_CENTER_FLOOR

func _ready() -> void:
	pass

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################

func _to_string() -> String:
	var print_color := Colors.to_print_color(Colors.get_action_point_color(type))
	return Util.color_string("AP-%s @%s" % [Enum.to_str(ActionType, type), grid_pos], print_color)
