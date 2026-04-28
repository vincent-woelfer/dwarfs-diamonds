class_name GridBoolArray
extends RefCounted

var bool_array: PackedByteArray

func _init() -> void:
    bool_array = PackedByteArray()
    bool_array.resize(Global.LEVEL_WIDTH * Global.LEVEL_HEIGHT)
    bool_array.fill(0)


func clear() -> void:
    bool_array.fill(0)


func get_value(pos: Vector2i) -> bool:
    return bool_array[_get_index(pos)] == 1

func set_value(pos: Vector2i, value: bool) -> void:
    bool_array[_get_index(pos)] = 1 if value else 0

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _get_index(pos: Vector2i) -> int:
    assert(Util.is_grid_pos_valid(pos))
    return pos.y * Global.LEVEL_WIDTH + pos.x

func _get_grid_pos(index: int) -> Vector2i:
    var y: int = index % Global.LEVEL_WIDTH
    var x: int = index - (y * Global.LEVEL_WIDTH)
    return Vector2i(x, y)
