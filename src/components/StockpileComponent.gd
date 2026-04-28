class_name StockpileComponent
extends Node2D

########################################################################################################################
# A stationary or moving. Handles picking up and dropping items, but also the visual placement of items on the carrier.
########################################################################################################################

@onready var parent: GridObject2D = get_parent()

var _storage: AbstractStorage = AbstractStorage.new()

########################################################################################################################
# ITEM PLACEMENT
########################################################################################################################
func _update_item_placement(delta: float) -> void:
	var item_type_group_sizes: Dictionary[Enum.ItemType, int] = _storage.get_item_type_group_sizes()
	var idx_by_type: Dictionary[Enum.ItemType, int] = {}

	for i: int in range(_storage.get_carried_total_count()):
		var item: Item = _storage.get_item_by_index(i)

		if item == null:
			continue # safety check, should not happen

		# Idx by type and group idx
		if not idx_by_type.has(item.item_type):
			idx_by_type[item.item_type] = 0
		var idx_in_group: int = idx_by_type[item.item_type]
		idx_by_type[item.item_type] += 1
		var group_idx: int = item.item_type as int

		var target_pos: Vector2 = _get_carried_item_position(item, idx_in_group, group_idx)

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
func _get_carried_item_position(item: Item, index_in_group: int, group_index: int) -> Vector2:
	var width_per_group := Global.CELL_SIZE * 0.5
	var left: bool = group_index % 2 == 0
	var horizontal_offset: float = width_per_group * (-1.0 if left else 1.0)

	# global_position should be floor center
	var base_pos: Vector2 = parent.global_position + Vector2(horizontal_offset, 0.0)

	# Include some overlap
	var item_size: Vector2 = item.get_stacking_size() * _storage.item_scaling_in_storage * Vector2(0.6, 0.9)

	# var items_per_row: int = max(floori((item_size.x / width_per_group)), 1)
	var items_per_row := 3

	# TODO does not work well
	var x_idx: int = index_in_group % items_per_row
	var y_idx: int = floori((index_in_group - x_idx as float) / items_per_row as float)

	return base_pos + Vector2(x_idx, -y_idx) * item_size


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _ready() -> void:
	assert(parent != null)
	assert(parent is GridObject2D)

	_storage.item_scaling_in_storage = 0.8


func _physics_process(delta: float) -> void:
	if is_carrying_anything():
		_update_item_placement(delta)


########################################################################################################################
# Overwritten methods from AbstractStorage - redirected to _storage
# Same for CarryComponent and StockpileComponent
########################################################################################################################
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

func transfer_to_other_storage(item: Item, other_storage: AbstractStorage) -> bool:
	return _storage.transfer_to_other_storage(item, other_storage)

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
