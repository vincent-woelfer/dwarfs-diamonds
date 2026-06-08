class_name StorageComponent
extends Node2D

########################################################################################################################
# Unified storage component. Handles storage, pickup/drop/capacity checks, and visual item placement.
########################################################################################################################
###################################
# Signals
###################################
## Emitted when full after picking up an item.
signal Signal_OnFull()

###################################
# Placement mode
###################################
enum PlacementMode { CARRY, STOCKPILE }
@export var placement_mode: PlacementMode = PlacementMode.CARRY

###################################
# Capacity mode
###################################
# COMBINED = max weight/count shared between all items.
# PER_ITEM_TYPE = max count per item type, weight is ignored
enum CapacityMode { COMBINED_WEIGHT_COUNT, PER_ITEM_TYPE_COUNT }
@export var capacity_mode: CapacityMode = CapacityMode.COMBINED_WEIGHT_COUNT

@export var capacity_combined_max_weight: float = 20.0
@export var capacity_combined_max_count: int = 10

@export var capacity_item_type_list: ItemTypeList = ItemTypeList.new()

###################################
# Placement tuning
###################################
@export var item_scaling_in_storage: float = 1.0

###################################
# Internal
###################################
@onready var parent: GridObject2D = get_parent()

var _curr_carried_items: Array[Item] = []
var _curr_total_weight: float = 0.0

# for placement logic
var _curr_item_type_list: ItemTypeList = ItemTypeList.new()


########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
###################################
# PICKUP - with range check (parent grid pos = item grid pos)
###################################
# Picks up all pickupable items in range until capacity is full, prioritizing the given items first.
# Returns true if ALL priority items were picked up
func pickup_all_in_range(priority_items: Array[Item]) -> bool:
	var items: Array[Item] = get_all_pickupable_items_in_range()
	var picked_up: Array[Item] = []

	# Sort so that priority items come first
	items.sort_custom(
		func(a: Item, b: Item) -> bool:
			var a_prio: bool = priority_items.has(a)
			var b_prio: bool = priority_items.has(b)
			return a_prio and not b_prio
	)

	for item: Item in items:
		if pickup(item):
			picked_up.append(item)

	# Check if all priority items were picked up
	for prio_item: Item in priority_items:
		if not picked_up.has(prio_item):
			return false

	return true


## Actually picks up the item if possible, returns false otherwise
func pickup(item: Item) -> bool:
	if not can_pickup(item):
		return false

	item.on_picked_up(self)
	_add(item)

	return true


###################################
# DROP
###################################
func drop(item: Item) -> Item:
	if item == null or not _curr_carried_items.has(item):
		return null

	_remove(item)
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

	_remove(item)
	item.queue_free()


###################################
# TRANSFER - no range checks, just capacity
###################################
func transfer_to_other_storage(item: Item, other_storage: StorageComponent) -> bool:
	if item == null or other_storage == null or not _curr_carried_items.has(item):
		return false

	if other_storage == self:
		return false

	# For now no range check
	if not other_storage.does_fit_into_capacity(item):
		return false

	# Remove, notify other storage and item
	_remove(item)
	other_storage.on_item_transfered_from_other_storage(item)
	item.on_transfered_to_other_storage(other_storage)

	return true


func on_item_transfered_from_other_storage(item: Item) -> void:
	_add(item)


###################################
# CAN PICKUP / CAPACITY CHECKS
###################################
## Can this carrier pick up the given item right now
func can_pickup(item: Item) -> bool:
	# Perform basic checks on item
	if item == null or not item.can_be_picked_up_right_now() or not does_fit_into_capacity(item):
		return false

	if not is_in_range(item):
		return false

	return true


## Can this carry component carry the given item at all (ignoring range etc)
## Used to filter jobs
func does_fit_into_capacity(item: Item) -> bool:
	if item == null:
		return false

	if capacity_mode == CapacityMode.COMBINED_WEIGHT_COUNT:
		if _curr_total_weight + item.weight > capacity_combined_max_weight:
			return false
		if _curr_carried_items.size() + 1 > capacity_combined_max_count:
			return false

	elif capacity_mode == CapacityMode.PER_ITEM_TYPE_COUNT:
		var curr: int = _curr_item_type_list.get_item_count_for_type(item.item_type)
		var max_for_type: int = capacity_item_type_list.get_item_count_for_type(item.item_type)
		if curr + 1 > max_for_type:
			return false

	return true


func is_in_range(item: Item) -> bool:
	# For now just check if in the same cell, later we can add a pickup radius or something
	return item.grid_pos == parent.grid_pos


###################################
# Getters
###################################
func is_carrying_anything() -> bool:
	return not _curr_carried_items.is_empty()


## Returns true if all required item types are full for CapacityMode.PER_ITEM_TYPE_COUNT
func is_full() -> bool:
	match capacity_mode:
		CapacityMode.PER_ITEM_TYPE_COUNT:
			return _curr_item_type_list.is_full(capacity_item_type_list)
		CapacityMode.COMBINED_WEIGHT_COUNT:
			return _curr_total_weight >= capacity_combined_max_weight or _curr_carried_items.size() >= capacity_combined_max_count
		_:
			assert(false)
			return false


func get_carried_total_weight() -> float:
	return _curr_total_weight


func get_carried_total_count() -> int:
	return _curr_carried_items.size()


func get_carried_weight_percentage() -> float:
	return _curr_total_weight / capacity_combined_max_weight


func get_curr_item_type_list() -> ItemTypeList:
	return _curr_item_type_list


func get_item_by_index(index: int) -> Item:
	if index < 0 or index >= _curr_carried_items.size():
		return null
	return _curr_carried_items[index]


func get_last_item() -> Item:
	return get_item_by_index(_curr_carried_items.size() - 1)


## Returns all pickupable items in range (currently same cell)
## The weight is only checked for each item alone, this doesnt mean all items can be picked up together
func get_all_pickupable_items_in_range() -> Array[Item]:
	var items: Array[Item] = []

	for item: Item in Global.level.item_manager.get_all_on_ground():
		if is_in_range(item) and can_pickup(item):
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
# ITEM PLACEMENT
##################################################################################1#####################################
func _update_item_placement(delta: float) -> void:
	var idx_by_type: ItemTypeList = ItemTypeList.new()

	for i: int in range(get_carried_total_count()):
		var item: Item = get_item_by_index(i)

		if item == null:
			continue # safety check, should not happen

		# Fetch data and increment
		var idx_in_group: int = idx_by_type.get_item_count_for_type(item.item_type)
		var group_idx: int = item.item_type as int
		idx_by_type.add(item.item_type)

		var target_pos: Vector2 = _get_item_target_position(item, idx_in_group, group_idx)

		# Lerp if animation not finished, snap once securely attached
		if item.transition_animation_finished:
			item.global_position = target_pos
		else:
			var time_since_pickup: float = Util.now() - item.transition_animation_start_time
			var animation_progress: float = clamp(time_since_pickup / item.transition_max_duration, 0.0, 1.0)

			# Move item
			item.global_position = item.global_position.lerp(target_pos, animation_progress)
			if animation_progress >= 1.0:
				item.transition_animation_finished = true

		# Also update item-parent grid pos to match carrier - even though this is probaly not required in most cases.
		item.update_grid_pos(parent.grid_pos)


## Returns global position
## Assumes all objects have their origin at center bottom. -Y is up.
func _get_item_target_position(item: Item, index_in_group: int, group_index: int) -> Vector2:
	match placement_mode:
		PlacementMode.CARRY:
			return _get_carry_item_position(item, index_in_group, group_index)
		PlacementMode.STOCKPILE:
			return _get_stockpile_item_position(item, index_in_group, group_index)
		_:
			assert(false)

	return self.global_position


func _get_carry_item_position(item: Item, index_in_group: int, group_index: int) -> Vector2:
	# Flip horizontal offset based on look dir if available
	var flip_horizontal: float = -1.0 if _get_parent_look_dir().x < 0.0 else 1.0

	# Base = "on back of dwarf" - flipped based on look dir
	var vertical_offset_base: float = Global.CELL_SIZE * 0.285
	var horizontal_offset_base: float = Global.CELL_SIZE * -0.3 # - so its slightly to the back of the dwarf
	var base_pos: Vector2 = self.global_position + Vector2(horizontal_offset_base * flip_horizontal, -vertical_offset_base)

	# Group offset - also flipped
	var offset_for_groups: Array[float] = [0.0, Global.CELL_SIZE * 0.2]
	var safe_group_index: int = mini(group_index, offset_for_groups.size() - 1)
	var group_offset: Vector2 = Vector2(offset_for_groups[safe_group_index] * flip_horizontal, 0.0)

	# Item offset - not flipped, just stacks up vertically per item in the same group
	return base_pos + group_offset + (index_in_group * item.get_stacking_size() * item_scaling_in_storage * Vector2.UP)


func _get_stockpile_item_position(item: Item, index_in_group: int, group_index: int) -> Vector2:
	var width_per_group: float = Global.CELL_SIZE * 0.5
	var left: bool = group_index % 2 == 0
	var horizontal_offset: float = width_per_group * (-1.0 if left else 1.0)

	# global_position should be floor center
	var base_pos: Vector2 = self.global_position + Vector2(horizontal_offset, 0.0)

	# Include some overlap
	var item_size: Vector2 = item.get_stacking_size() * item_scaling_in_storage * Vector2(0.6, 0.9)

	return base_pos + Vector2(0.0, -index_in_group * item_size.y)


########################################################################################################################
# SETUP
########################################################################################################################
func setup(capacity_mode_: CapacityMode, placement_mode_: PlacementMode) -> StorageComponent:
	capacity_mode = capacity_mode_
	placement_mode = placement_mode_
	return self


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _ready() -> void:
	assert(parent != null)
	assert(parent is GridObject2D)

	match placement_mode:
		PlacementMode.CARRY:
			item_scaling_in_storage = 0.75
		PlacementMode.STOCKPILE:
			item_scaling_in_storage = 0.5


func _exit_tree() -> void:
	# Drop all items on exit, so they dont get lost. This should not happen often,
	drop_all()


func _physics_process(delta: float) -> void:
	if is_carrying_anything():
		_update_item_placement(delta)


func _get_parent_look_dir() -> Vector2:
	var look_dir: Variant = parent.get("look_dir")
	if look_dir != null and look_dir is Vector2:
		@warning_ignore("unsafe_cast")
		return look_dir as Vector2

	# default look dir if not available
	return Vector2.RIGHT


###################################
# ONLY place where items are actually added/removed from storage, all checks should be done before calling these
###################################
func _add(item: Item) -> void:
	_curr_carried_items.append(item)
	_curr_total_weight += item.weight
	_curr_item_type_list.add(item.item_type, 1)

	if is_full():
		Signal_OnFull.emit()


func _remove(item: Item) -> void:
	_curr_carried_items.erase(item)
	_curr_total_weight -= item.weight
	_curr_item_type_list.subtract(item.item_type, 1)
