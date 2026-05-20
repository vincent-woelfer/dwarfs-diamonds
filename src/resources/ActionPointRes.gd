@tool
class_name ActionPointRes
extends Resource

## Type of action point
@export var type: ActionPoint.ApType

## Local offset from the building's origin grid position
@export var grid_offset: Vector2i = Vector2i.ZERO

# Only for editor visualization
@export_custom(PROPERTY_HINT_COLOR_NO_ALPHA, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY)
var color: Color:
    get:
        return Colors.get_action_point_color(self.type)
