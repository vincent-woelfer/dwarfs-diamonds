@tool
class_name GridPattern
extends Resource

@export var world_offset: Vector2i = Vector2i.ZERO
@export var pattern: Array[Vector2i] = []


func _init(pattern_: Array[Vector2i] = [], world_offset_: Vector2i = Vector2i.ZERO) -> void:
    world_offset = world_offset_
    pattern = _remove_duplicates(pattern_)

func _remove_duplicates(array: Array[Vector2i]) -> Array[Vector2i]:
    var unique_positions: Dictionary[Vector2i, bool] = {}
    for pos in array:
        unique_positions[pos] = true
    return (unique_positions.keys() as Array[Vector2i])

func get_local_positions() -> Array[Vector2i]:
    return pattern
    

func get_world_positions() -> Array[Vector2i]:
    var world_positions: Array[Vector2i] = []
    for local_pos in pattern:
        world_positions.append(local_pos + world_offset)
    return world_positions
