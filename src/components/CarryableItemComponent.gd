class_name CarryableItemComponent
extends Node2D

#########################################################################################################################
# Items (The item itself and the CarryableItemComponent) are not reparented, they are always children of the global root node.
#########################################################################################################################

## Emitted when picked-up or dropped
signal Signal_OnPickedUp()
signal Signal_OnDropped()

# Configurable properties - Set by item itself
var weight: float = 1.0
var item_type: Item.ItemType

# Storage state
var is_in_storage: bool = false
var storage: AbstractStorage = null

# Pick-up animation state
var pick_up_animation_finished: bool = false
var pick_up_animation_start_time: float = 0.0

# Own parent (the item itself)
@onready var parent: GridObject2D = get_parent()


# Since this is a component the parent can not override this method.
# Therefore we check by duck-typing whether the parent has additional pick-up requirements.
func can_be_picked_up_right_now() -> bool:
	if is_in_storage:
		return false

	# Check parent requirements (if any)
	var parent_allow_pickup := true
	if parent.has_method("_can_be_picked_up"):
		@warning_ignore("UNSAFE_METHOD_ACCESS")
		parent_allow_pickup = parent._can_be_picked_up()

	return parent_allow_pickup


func delete_self() -> void:
	parent.queue_free()

########################################################################################################################
# For moving the parent component
########################################################################################################################
func move_parent(new_global_position: Vector2) -> void:
	parent.global_position = new_global_position

func set_parent_grid_pos(new_grid_pos: Vector2i) -> void:
	parent.update_grid_pos(new_grid_pos)


########################################################################################################################
# Only for additional logic specific to this item. Override in subclasses. 
# is_in_storage + storage will be handled by CarryComponent.
########################################################################################################################
# Overrite (and call super. on_picked_up) to add any logic needed when picked up
func on_picked_up(new_storage: AbstractStorage) -> void:
	is_in_storage = true
	storage = new_storage
	
	pick_up_animation_finished = false
	pick_up_animation_start_time = Util.now()
	Signal_OnPickedUp.emit()

# Overrite (and call super.on_dropped) to add any logic needed when dropped
func on_dropped() -> void:
	is_in_storage = false
	storage = null
	Signal_OnDropped.emit()


########################################################################################################################
# INTERNAL METHODS
########################################################################################################################
func _ready() -> void:
	add_to_group(Global.GROUP_CARRYABLE_ITEMS)
	assert(parent != null)
	assert(parent is GridObject2D)


func _to_string() -> String:
	return parent.to_string()
