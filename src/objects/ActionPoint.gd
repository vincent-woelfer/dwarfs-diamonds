class_name ActionPoint
extends GridObject2D

###################################
# ENUM DEFINITIONS
###################################
enum ApType {
	DROPOFF_RUBBLE,
	DROPOFF_GEMSTONE,
	CONSTR_MAT_STOCKPILE,
}


###################################
# Variables
###################################
var is_active: bool = true

var type: ApType

## May be own child, may be not
var storage_comp: StorageComponent = null


########################################################################################################################
# SETUP
########################################################################################################################
static func setup_bare_ap(grid_pos_: Vector2i, type_: ApType) -> ActionPoint:
	var ap := ActionPoint.new()
	ap.setup_grid_object(grid_pos_, Vector2.ZERO)
	ap.type = type_
	return ap

func setup_dropoff_ap() -> void:
	assert(type in [ApType.DROPOFF_RUBBLE, ApType.DROPOFF_GEMSTONE])

	storage_comp = StorageComponent.new()
	storage_comp.position = Global.CELL_OFFSET_CENTER_FLOOR
	storage_comp.placement_mode = StorageComponent.PlacementMode.STOCKPILE
	storage_comp.capacity_mode = StorageComponent.CapacityMode.COMBINED_WEIGHT_COUNT
	add_child(storage_comp)


## Takes existing storage
func setup_constr_mat_stockpile_ap(storage: StorageComponent, required_materials: ItemTypeList) -> void:
	assert(type == ApType.CONSTR_MAT_STOCKPILE)

	storage_comp = storage
	storage_comp.position = Global.CELL_OFFSET_CENTER_FLOOR
	storage_comp.placement_mode = StorageComponent.PlacementMode.STOCKPILE
	storage_comp.capacity_mode = StorageComponent.CapacityMode.PER_ITEM_TYPE_COUNT
	storage_comp.capacity_per_item_type_dict = required_materials

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

	var first_part := Util.color_string("AP-%s (" % [Enum.to_str(ApType, type)], print_color)
	var active_str := Util.color_string("Active", print_color.lerp(Color.GREEN, 0.5)) if is_active else Util.color_string("Inactive", print_color.lerp(Color.RED, 0.5))
	var second_part := Util.color_string(") @%s" % [grid_pos], print_color)

	return first_part + active_str + second_part
