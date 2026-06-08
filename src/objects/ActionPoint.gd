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

## NOT owned, only reference
var storage_comp: StorageComponent = null


########################################################################################################################
# SETUP
########################################################################################################################
static func setup_dropoff_ap(grid_pos_: Vector2i, storage: StorageComponent, type_: ApType) -> ActionPoint:
	assert(type_ in [ApType.DROPOFF_RUBBLE, ApType.DROPOFF_GEMSTONE])

	var ap := ActionPoint.new(type_, grid_pos_)
	ap.storage_comp = storage
	return ap

	# storage_comp.position = Global.CELL_OFFSET_CENTER_FLOOR
	# storage_comp.placement_mode = StorageComponent.PlacementMode.STOCKPILE
	# storage_comp.capacity_mode = StorageComponent.CapacityMode.COMBINED_WEIGHT_COUNT


## Takes existing storage
static func setup_constr_mat_stockpile_ap(grid_pos_: Vector2i, storage: StorageComponent) -> ActionPoint:
	var ap := ActionPoint.new(ApType.CONSTR_MAT_STOCKPILE, grid_pos_)
	ap.storage_comp = storage

	# ap.storage_comp.position = Global.CELL_OFFSET_CENTER_FLOOR
	# ap.storage_comp.placement_mode = StorageComponent.PlacementMode.STOCKPILE
	# ap.storage_comp.capacity_mode = StorageComponent.CapacityMode.PER_ITEM_TYPE_COUNT
	# ap.storage_comp.capacity_item_type_list = required_materials

	return ap


func _ready() -> void:
	pass

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _init(type_: ApType, grid_pos_: Vector2i) -> void:
	self.type = type_
	self.setup_grid_object(grid_pos_, Vector2.ZERO)


func _to_string() -> String:
	var print_color := Colors.to_print_color(Colors.get_action_point_color(type))

	var first_part := Util.color_string("AP-%s (" % [Enum.to_str(ApType, type)], print_color)
	var active_str := Util.color_string("Active", print_color.lerp(Color.GREEN, 0.5)) if is_active else Util.color_string("Inactive", print_color.lerp(Color.RED, 0.5))
	var second_part := Util.color_string(") @%s" % [grid_pos], print_color)

	return first_part + active_str + second_part
