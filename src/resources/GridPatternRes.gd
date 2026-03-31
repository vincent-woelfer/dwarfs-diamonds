@tool
class_name GridPatternRes
extends Resource

@export var cells: Array[Vector2i] = []

# internal variable
var _world_offset: Vector2i = Vector2i.ZERO


static func init_from_pattern(other_pattern_: GridPatternRes, world_offset_: Vector2i = Vector2i.ZERO) -> GridPatternRes:
    if other_pattern_ == null:
        return GridPatternRes.new([], world_offset_)
    else:
        return GridPatternRes.new(other_pattern_.cells, world_offset_)

func _init(cells_: Array[Vector2i] = [], world_offset_: Vector2i = Vector2i.ZERO) -> void:
    assert(cells_ != null)
    cells = _remove_duplicates(cells_)
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
