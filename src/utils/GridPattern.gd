class_name GridPattern
extends Resource

@export var world_offset: Vector2i
@export var pattern: Array[Vector2i]


func _init(pattern_: Array[Vector2i] = [], world_offset_: Vector2i = Vector2i.ZERO) -> void:
    pattern = pattern_
    world_offset = world_offset_


func get_local_positions() -> Array[Vector2i]:
    return pattern
    

func get_world_positions() -> Array[Vector2i]:
    var world_positions: Array[Vector2i] = []
    for local_pos in pattern:
        world_positions.append(local_pos + world_offset)
    return world_positions
