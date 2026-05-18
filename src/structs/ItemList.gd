class_name ItemTypeList
extends RefCounted

var item_type_list: Dictionary[Enum.ItemType, int] = {}

func _init(item_type_list_: Dictionary[Enum.ItemType, int] = {}) -> void:
	self.item_type_list = item_type_list_


func get_item_count(item_type: Enum.ItemType) -> int:
	return item_type_list.get(item_type, 0)


func increment_item_count(item_type: Enum.ItemType, amount: int = 1) -> int:
	# Ensure item type is in list
	if not item_type_list.has(item_type):
		item_type_list[item_type] = 0

	item_type_list[item_type] += amount
	return item_type_list[item_type]
