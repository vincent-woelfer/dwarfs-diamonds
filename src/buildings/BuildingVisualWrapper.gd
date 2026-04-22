@tool
class_name BuildingVisualWrapper
extends Node2D

## Only setting to show/hide child notes depending on construction progress
@export_range(0.0, 1.0, 0.1) var visible_after_progress: float = 0.0:
	set(value):
		visible_after_progress = clampf(value, 0.0, 1.0)
		update_building_progress(visible_after_progress)
		_request_parent_update()


func update_building_progress(progress: float) -> void:
	self.visible = progress >= visible_after_progress


## Shared Visual-Child Method
func _request_parent_update() -> void:
	if get_parent() is BuildingVisualRoot:
		(get_parent() as BuildingVisualRoot).refresh_child_node(self )
