@tool
class_name GridPatternRes
extends Resource

@export var cells: Array[Vector2i] = []

# internal variable
var _world_offset: Vector2i = Vector2i.ZERO


func _init(pattern_: Array[Vector2i] = [], world_offset_: Vector2i = Vector2i.ZERO) -> void:
    assert(pattern_ != null)
    cells = _remove_duplicates(pattern_)
    _world_offset = world_offset_


func _remove_duplicates(array: Array[Vector2i]) -> Array[Vector2i]:
    var unique_positions: Dictionary[Vector2i, bool] = {}
    for pos in array:
        unique_positions[pos] = true
    return (unique_positions.keys() as Array[Vector2i])


func get_local_positions() -> Array[Vector2i]:
    return cells
    

func get_world_positions() -> Array[Vector2i]:
    var world_positions: Array[Vector2i] = []
    for local_pos in cells:
        world_positions.append(local_pos + _world_offset)
    return world_positions
