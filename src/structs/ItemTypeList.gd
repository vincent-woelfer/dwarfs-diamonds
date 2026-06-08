class_name ItemTypeList
extends Resource

@export var item_dict: Dictionary[Enum.ItemType, int] = { }


func _init(item_dict_: Dictionary[Enum.ItemType, int] = { }) -> void:
	self.item_dict = item_dict_


########################################################################################################################
# PUBLIC METHODS - INCREMENT / DECREMENT
########################################################################################################################
func add(item_type: Enum.ItemType, amount: int = 1) -> int:
	if amount < 0:
		push_warning("Trying to add item type %s by negative amount %d, ignoring" % [Enum.to_str(Enum.ItemType, item_type), amount])
		return item_dict.get(item_type, 0)

	# Ensure item type is in list
	if not item_dict.has(item_type):
		item_dict[item_type] = 0

	item_dict[item_type] += amount
	return item_dict[item_type]


func subtract(item_type: Enum.ItemType, amount: int = 1) -> int:
	if amount < 0:
		push_warning("Trying to subtract item type %s by negative amount %d, ignoring" % [Enum.to_str(Enum.ItemType, item_type), amount])
		return item_dict.get(item_type, 0)

	# If not present just return 0, no negative numbers allowed
	if not item_dict.has(item_type):
		push_warning("Trying to subtract item type %s which is not in list, returning 0" % [Enum.to_str(Enum.ItemType, item_type)])
		return 0

	var new_val: int = max(item_dict[item_type] - amount, 0)
	item_dict[item_type] = new_val

	# If count has reached 0, remove item type from list to keep things clean
	if new_val == 0:
		item_dict.erase(item_type)

	return new_val


########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func clear() -> void:
	item_dict.clear()


func is_empty() -> bool:
	return item_dict.is_empty()


## Returns count of item type, or 0 if not present
func get_item_count_for_type(item_type: Enum.ItemType) -> int:
	return item_dict.get(item_type, 0)


## Returns total combined count of all items
func get_item_count_total() -> int:
	var total: int = 0
	for item_type: Enum.ItemType in item_dict.keys():
		total += item_dict[item_type]

	return total


func get_keys() -> Array[Enum.ItemType]:
	return item_dict.keys()


func is_full(definition_of_full: ItemTypeList) -> bool:
	for item_type: Enum.ItemType in definition_of_full.get_keys():
		var curr: int = self.get_item_count_for_type(item_type)
		var expected: int = definition_of_full.get_item_count_for_type(item_type)
		if curr < expected:
			return false

	return true


func _to_string() -> String:
	var item_strings: Array[String] = []
	for item_type: Enum.ItemType in item_dict.keys():
		var count: int = item_dict[item_type]
		item_strings.append("%s: %d" % [Enum.to_str(Enum.ItemType, item_type), count])

	return "[%s]" % ", ".join(item_strings)
