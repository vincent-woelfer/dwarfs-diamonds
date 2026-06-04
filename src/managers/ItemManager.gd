class_name ItemManager
extends Node2D

########################################################################################################################
# Handles all items in the level, including spawning and fetching data about them.
# Owns all items (as in all items are children of this node).
########################################################################################################################
# List of all items in the level, including on-ground and in-storage.
# TODO maybe optimize later.
var _items: Array[Item] = []


########################################################################################################################
# SPAWNING / ADDING / DELETING
########################################################################################################################
func spawn_item_in_cell(grid_pos: Vector2i, type: Enum.ItemType) -> void:
	var item: Item = _get_item_scene(type).instantiate()

	# Spawn offset
	var spawn_offset := Vector2(0, -Global.CELL_SIZE * 0.3) # Spawn above floor

	# Random horizontal offset to avoid perfect stacking and make it look more natural
	var max_horizontal_offset := Global.CELL_SIZE * 0.35
	spawn_offset.x = randf_range(-max_horizontal_offset, max_horizontal_offset)

	# Setup item
	item.setup_item(grid_pos, spawn_offset)

	# Add to scene and list
	add_child(item)
	_items.append(item)

# TODO spawn in storage

# TODO delete


########################################################################################################################
# Fetching Data
########################################################################################################################
func get_all() -> Array[Item]:
	return _items


func get_all_on_ground() -> Array[Item]:
	return _items.filter(
		func(item: Item) -> bool:
			return not item.is_in_storage
	)


########################################################################################################################
# Private Methods
########################################################################################################################
func _get_item_scene(type: Enum.ItemType) -> PackedScene:
	match type:
		Enum.ItemType.RUBBLE:
			return rubble_scene
		Enum.ItemType.GEMSTONE:
			return gemstone_scene
		Enum.ItemType.STONE:
			return stone_scene
		_:
			assert(false, "Invalid item type %s" % [type])
			return null

########################################################################################################################
# ITEM SCENES
########################################################################################################################
# must be load (not preload) due to circular reference!!!
var rubble_scene: PackedScene = load('res://scenes/objects/Rubble.tscn') as PackedScene
var gemstone_scene: PackedScene = load('res://scenes/objects/Gemstone.tscn') as PackedScene
var stone_scene: PackedScene = load('res://scenes/objects/Stone.tscn') as PackedScene
