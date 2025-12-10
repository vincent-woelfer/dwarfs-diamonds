class_name CarryComponent
extends Node2D

## Emitted when building completed
# signal Signal_OnBuildingCompleted(building: BuildingBase)


@export var carry_capacity: float = 10.0

# internal
var _curr_carried_items: Array[CarryableItemComponent] = []
var _curr_total_weight: float = 0.0

var parent: GridObject2D = null

# ########################################################################################################################
# # PUBLIC METHODS
# ########################################################################################################################

## Actually picks up the item if possible, returns false otherwise
func pickup(item: CarryableItemComponent) -> bool:
	if not can_pickup(item):
		return false

	# Modify self
	_curr_carried_items.append(item)
	_curr_total_weight += item.weight

	# Modify item
	item.is_being_carried = true
	item.carrier = self
	item.on_picked_up()

	# TODO add acutal pickup code here

	return true


## Just performs checks whether the item can be picked up
func can_pickup(item: CarryableItemComponent) -> bool:
	# Perform basic checks
	if item == null or not item.can_be_picked_up():
		return false

	# Check weight capacity
	var new_total_weight := _curr_total_weight + item.weight
	if new_total_weight > carry_capacity:
		return false

	# Check pickup range (currently same cell)
	if item.parent.grid_pos != parent.grid_pos:
		return false

	return true


func drop(item: CarryableItemComponent) -> void:
	if item == null or not _curr_carried_items.has(item):
		return

	# Modify self
	_curr_carried_items.erase(item)
	_curr_total_weight -= item.weight

	# Modify item
	item.is_being_carried = false
	item.carrier = null
	item.on_dropped()

	# TODO add actual drop code here


func drop_all() -> void:
	# Duplicate the array to allow modification during iteration
	for item: CarryableItemComponent in _curr_carried_items.duplicate():
		drop(item)


func is_carrying() -> bool:
	return not _curr_carried_items.is_empty()


func get_carried_total_weight() -> float:
	return _curr_total_weight


func get_all_pickupable_items_in_range() -> Array[CarryableItemComponent]:
	var items: Array[CarryableItemComponent] = []
	for item: CarryableItemComponent in Global.get_group(Global.GROUP_CARRYABLE_ITEMS):
		# For performance, first check grid pos
		if item.parent.grid_pos != parent.grid_pos:
			continue

		if can_pickup(item):
			items.append(item)

	return items


# ########################################################################################################################
# # PRIVATE METHODS
# ########################################################################################################################
func _ready() -> void:
	# Get and verify parent
	parent = get_parent()
	assert(parent != null)
	assert(parent is GridObject2D)

