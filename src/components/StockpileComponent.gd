class_name StockpileComponent
extends Node2D

########################################################################################################################
# A stationary or moving. Handles picking up and dropping items, but also the visual placement of items on the carrier.
########################################################################################################################

@onready var parent: GridObject2D = get_parent()

var _storage: AbstractStorage = AbstractStorage.new()

# TODO variables for storage space visualisation.

########################################################################################################################
# ITEM PLACEMENT
########################################################################################################################
func _update_item_placement(delta: float) -> void:
	var item_type_group_sizes: Dictionary[Enum.ItemType, int] = _storage.get_item_type_group_sizes()
	var idx_by_type: Dictionary[Enum.ItemType, int] = {}

	for i: int in range(_storage.get_carried_total_count()):
		var item: Item = _storage.get_item_by_index(i)

		# Idx by type and group idx
		if not idx_by_type.has(item.item_type):
			idx_by_type[item.item_type] = 0
		var idx_in_group: int = idx_by_type[item.item_type]
		idx_by_type[item.item_type] += 1
		var group_idx: int = item.item_type as int

		var target_pos: Vector2 = _get_carried_item_position(item.item_type, idx_in_group, group_idx)

		# Lerp if animation not finished, snap once securely attached
		if item.transition_animation_finished:
			item.global_position = target_pos
		else:			
			var time_since_pickup: float = Util.now() - item.transition_animation_start_time
			var animation_progress: float = clamp(time_since_pickup / item.max_transition_duration, 0.0, 1.0)

			# Move item
			item.global_position = item.global_position.lerp(target_pos, animation_progress)
			if animation_progress >= 1.0:
				item.transition_animation_finished = true
		
		# Also update item-parent grid pos to match carrier - even though this is probaly not required in most cases.
		item.update_grid_pos(parent.grid_pos)
	

## Returns global position
## Assumes all objects have their origin at center bottom. -Y is up.
func _get_carried_item_position(item_type: Enum.ItemType, index_in_group: int, group_index: int) -> Vector2:
	var vertical_offset_base: float = Global.CELL_SIZE * 0.285
	var horizontal_offset_base: float = Global.CELL_SIZE * -0.3 # - so its slightly to the back of the dwarf
	var base_pos: Vector2 = parent.global_position + Vector2(horizontal_offset_base, -vertical_offset_base)

	# Group offset - also flipped
	var offset_for_groups: Array[float] = [0.0, Global.CELL_SIZE * 0.2]
	var group_offset := Vector2(offset_for_groups[group_index], 0.0)

	# Item offset - not flipped, just stacks up vertically per item in the same group
	var offset_y_per_item := Vector2(0.0, -Global.CELL_SIZE * 0.15)

	return base_pos + group_offset + index_in_group * offset_y_per_item


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _ready() -> void:
	assert(parent != null)
	assert(parent is GridObject2D)


func _physics_process(delta: float) -> void:
	if is_carrying_anything():
		_update_item_placement(delta)


########################################################################################################################
# Overwritten methods from AbstractStorage - redirected to _storage
########################################################################################################################
# TODO DROP/TRansfer to other container/storage/disposal

func pickup_all_in_range(priority_items: Array[Item]) -> bool:
	return _storage.pickup_all_in_range(parent.grid_pos, priority_items)

func pickup(item: Item) -> bool:
	return _storage.pickup(parent.grid_pos, item)

func drop(item: Item) -> void:
	_storage.drop(item)

func drop_all() -> void:
	_storage.drop_all()

func delete(item: Item) -> void:
	_storage.delete(item)

func can_pickup(item: Item) -> bool:
	return _storage.can_pickup(parent.grid_pos, item)

func can_carry_ignoring_position(item: Item) -> bool:
	return _storage.does_fit_into_capacity(item)

func is_carrying_anything() -> bool:
	return _storage.is_carrying_anything()

func get_carried_total_weight() -> float:
	return _storage.get_carried_total_weight()

func get_carried_weight_percentage() -> float:
	return _storage.get_carried_weight_percentage()

func get_all_pickupable_items_in_range() -> Array[Item]:
	return _storage.get_all_pickupable_items_in_range(parent.grid_pos)

func is_carrying_item_of_type(item_type: Enum.ItemType) -> bool:
	return _storage.is_carrying_item_of_type(item_type)

func get_items_of_type(item_type: Enum.ItemType) -> Array[Item]:
	return _storage.get_items_of_type(item_type)
