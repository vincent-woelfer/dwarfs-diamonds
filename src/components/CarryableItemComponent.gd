class_name CarryableItemComponent
extends Node2D

@export var weight: float = 1.0

# Internal state
var is_being_carried: bool = false
var carrier: CarryComponent = null

# Own parent
var parent: GridObject2D = null


func can_be_picked_up() -> bool:
    return not is_being_carried


########################################################################################################################
# Only for additional logic specific to this item. Override in subclasses. 
# is_being_carried + carrier will be handled by CarryComponent.
########################################################################################################################
func on_picked_up() -> void:
    # TODO add any logic needed when picked up
    pass


func on_dropped() -> void:
    # TODO add any logic needed when dropped
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
