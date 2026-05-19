class_name ItemTypeList
extends Resource

@export var item_dict: Dictionary[Enum.ItemType, int] = {}

func _init(item_dict_: Dictionary[Enum.ItemType, int] = {}) -> void:
	self.item_dict = item_dict_


func clear() -> void:
	item_dict.clear()

func is_empty() -> bool:
	return item_dict.is_empty()


func get_item_count(item_type: Enum.ItemType) -> int:
	return item_dict.get(item_type, 0)


func increment_item_count(item_type: Enum.ItemType, amount: int = 1) -> int:
	# Ensure item type is in list
	if not item_dict.has(item_type):
		item_dict[item_type] = 0

	item_dict[item_type] += amount
	return item_dict[item_type]


func _to_string() -> String:
	var item_strings: Array[String] = []
	for item_type: Enum.ItemType in item_dict.keys():
		var count: int = item_dict[item_type]
		item_strings.append("%s: %d" % [Enum.to_str(Enum.ItemType, item_type), count])

	return "[%s]" % ", ".join(item_strings)
