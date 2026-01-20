@tool
class_name ActionPointRes
extends Resource

## Type of action point
@export var type: ActionPoint.ActionType

## Local offset from the building's origin grid position
@export var local_grid_offset: Vector2i = Vector2i.ZERO
