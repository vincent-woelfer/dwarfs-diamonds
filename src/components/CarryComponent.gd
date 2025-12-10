class_name CarryComponent
extends Node2D

## Emitted when building completed
# signal Signal_OnBuildingCompleted(building: BuildingBase)


@export var carry_capacity: float = 2.0

# internal
var _curr_carried_items: Array[CarryableItemComponent] = []
var _curr_total_weight: float = 0.0

@onready var parent: GridObject2D = get_parent()

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
	item.pick_up_animation_finished = false
	item.on_picked_up()

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
	item.on_dropped()
	item.is_being_carried = false
	item.carrier = null

	# Set item position to be inside cell of carrier
	item.parent.global_position = parent.global_position


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
	assert(parent != null)
	assert(parent is GridObject2D)


func _physics_process(delta: float) -> void:
	# Update positions of carried items
	for i in _curr_carried_items.size():
		var item: CarryableItemComponent = _curr_carried_items[i]
		var item_parent: GridObject2D = item.parent
		var target_pos: Vector2 = _get_carried_item_position(i)

		# Lerp if animation not finished, snap once securely attached
		if item.pick_up_animation_finished:
			item_parent.global_position = target_pos
		else:
			var speed: float = 8.0
			var threshold: float = Global.CELL_SIZE * 0.05

			item_parent.global_position = item_parent.global_position.lerp(target_pos, delta * speed)
			if item_parent.global_position.distance_to(target_pos) <= threshold:
				item.pick_up_animation_finished = true
				item_parent.global_position = target_pos
		
		# Also update item-parent grid pos to match carrier
		item_parent.update_grid_pos(parent.grid_pos)


## Returns global position
func _get_carried_item_position(idx: int) -> Vector2:
	# Simple stacking logic
	# Assumes all objects have their origin at center bottom. -Y is up.
	var vertical_offset_base: float = Global.CELL_SIZE * 0.3
	var horizontal_offset: float = Global.CELL_SIZE * -0.15 # - so its slightly to the back of the dwarf

	if parent.get("look_dir"):
		if parent.get("look_dir").x < 0:
			horizontal_offset = - horizontal_offset

	var base_pos: Vector2 = parent.global_position + Vector2(horizontal_offset, -vertical_offset_base)

	var offset_y_per_item: float = idx * Global.CELL_SIZE * 0.15

	return base_pos + Vector2(0.0, offset_y_per_item)
