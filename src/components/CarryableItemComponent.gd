@abstract
class_name CarryableItemComponent
extends Node2D

@export var weight: float = 1.0

# Internal state
var is_being_carried: bool = false
var carrier: CarryComponent = null

# Own parent
var parent: GridObject2D = null


# Since this is a component the parent can not override this method.
# Therefore we check by duck-typing whether the parent has additional pick-up requirements.
func can_be_picked_up() -> bool:
    var parent_allow_pickup := true

    if parent.has_method("_can_be_picked_up"):
        @warning_ignore("UNSAFE_METHOD_ACCESS")
        parent_allow_pickup = parent._can_be_picked_up()

    return parent_allow_pickup and (!is_being_carried)

########################################################################################################################
# Only for additional logic specific to this item. Override in subclasses. 
# is_being_carried + carrier will be handled by CarryComponent.
########################################################################################################################
# Overrite to add any logic needed when picked up
func on_picked_up() -> void:
    pass

# Overrite to add any logic needed when dropped
func on_dropped() -> void:
    pass


########################################################################################################################
# INTERNAL METHODS
########################################################################################################################
func _ready() -> void:
    add_to_group(Global.GROUP_CARRYABLE_ITEMS)

    # Get and verify parent
    parent = get_parent()
    assert(parent != null)
    assert(parent is GridObject2D)


func _to_string() -> String:
    return parent.to_string()
