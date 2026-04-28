class_name AbstractStorage
extends RefCounted

########################################################################################################################
# Abstract storage class, does NOT handle any placement logic, just the storage of items and capacity checks.
########################################################################################################################

# Storage capacity 
@export var capacity_max_weight: float = 5.0
@export var capacity_max_count: int = 10

# internal
var _curr_carried_items: Array[Item] = []
var _curr_total_weight: float = 0.0

# for placement logic
var _item_type_group_sizes: Dictionary[Enum.ItemType, int]

# Overwrite in child classes!
var in_storage_scaling: float = 1.0

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
###################################
# PICKUP
###################################
# Picks up all pickupable items in range until capacity is full, prioritizing the given items first.
# Returns true if ALL priority items were picked up
func pickup_all_in_range(carrier_pos: Vector2i, priority_items: Array[Item]) -> bool:
	var items: Array[Item] = get_all_pickupable_items_in_range(carrier_pos)
	var picked_up: Array[Item] = []

	# Sort so that priority items come first
	items.sort_custom(func(a: Item, b: Item) -> bool:
		var a_prio: bool = priority_items.has(a)
		var b_prio: bool = priority_items.has(b)
		return a_prio and not b_prio
	)

	for item: Item in items:
		if pickup(carrier_pos, item):
			picked_up.append(item)

	# Check if all priority items were picked up
	for prio_item: Item in priority_items:
		if not picked_up.has(prio_item):
			return false

	return true

## Actually picks up the item if possible, returns false otherwise
func pickup(carrier_pos: Vector2i, item: Item) -> bool:
	if not can_pickup(carrier_pos, item):
		return false

	# Modify self
	_curr_carried_items.append(item)
	_curr_total_weight += item.weight
	_update_item_type_group_sizes()

	# Modify item
	item.on_picked_up(self )

	return true


###################################
# DROP
###################################
func drop(item: Item) -> Item:
	if item == null or not _curr_carried_items.has(item):
		return null

	# Modify self
	_curr_carried_items.erase(item)
	_curr_total_weight -= item.weight
	_update_item_type_group_sizes()

	# Modify item
	item.on_dropped()

	return item


func drop_all() -> Array[Item]:
	# Duplicate the array to allow modification during iteration
	var dropped_items: Array[Item] = []

	for item: Item in _curr_carried_items.duplicate():
		dropped_items.append(drop(item))

	return dropped_items


###################################
# DELETE
###################################
func delete(item: Item) -> void:
	if item == null or not _curr_carried_items.has(item):
		return

	# Modify self
	_curr_carried_items.erase(item)
	_curr_total_weight -= item.weight

	_update_item_type_group_sizes()

	item.queue_free()


###################################
# CAN CARRY / PICKUP CHECKS
###################################
## Can this carrier pick up the given item right now
func can_pickup(carrier_pos: Vector2i, item: Item) -> bool:
	# Perform basic checks on item
	if item == null or not item.can_be_picked_up_right_now() or not does_fit_into_capacity(item):
		return false

	# Check pickup range (currently same cell)
	if item.grid_pos != carrier_pos:
		return false

	return true


## Can this carry component carry the given item at all (ignoring range etc)
## Used to filter jobs
func does_fit_into_capacity(item: Item) -> bool:
	# Check capacity
	if _curr_total_weight + item.weight > capacity_max_weight:
		return false

	if _curr_carried_items.size() + 1 > capacity_max_count:
		return false

	return true

###################################
# Getters
###################################
func is_carrying_anything() -> bool:
	return not _curr_carried_items.is_empty()

func get_carried_total_weight() -> float:
	return _curr_total_weight

func get_carried_total_count() -> int:
	return _curr_carried_items.size()

func get_carried_weight_percentage() -> float:
	return _curr_total_weight / capacity_max_weight


func get_item_type_group_sizes() -> Dictionary[Enum.ItemType, int]:
	return _item_type_group_sizes


func get_item_by_index(index: int) -> Item:
	if index < 0 or index >= _curr_carried_items.size():
		return null
	return _curr_carried_items[index]


## Returns all pickupable items in range (currently same cell)
## The weight is only checked for each item alone, this doesnt mean all items can be picked up together
func get_all_pickupable_items_in_range(carrier_pos: Vector2i) -> Array[Item]:
	var items: Array[Item] = []
	for item: Item in Global.get_group(Global.GROUP_CARRYABLE_ITEMS):
		# For performance, first check grid pos
		if item.grid_pos != carrier_pos:
			continue
		if can_pickup(carrier_pos, item):
			items.append(item)

	return items


func is_carrying_item_of_type(item_type: Enum.ItemType) -> bool:
	for item: Item in _curr_carried_items:
		if item.item_type == item_type:
			return true
	return false


func get_items_of_type(item_type: Enum.ItemType) -> Array[Item]:
	return _curr_carried_items.filter(func(item: Item) -> bool: return item.item_type == item_type)

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
## Internal helper to efficiently keep track of items per type, used for placement logic
func _update_item_type_group_sizes() -> void:
	_item_type_group_sizes = {}
	for item: Item in _curr_carried_items:
		if not _item_type_group_sizes.has(item.item_type):
			_item_type_group_sizes[item.item_type] = 0
		_item_type_group_sizes[item.item_type] += 1
