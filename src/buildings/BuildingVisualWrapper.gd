@tool
class_name BuildingVisualWrapper
extends Node2D

var progress: float

## Only setting to show/hide child notes depending on construction progress
@export_range(0.0, 1.0, 0.1) var visible_after_progress: float = 0.0:
	set(value):
		visible_after_progress = clampf(value, 0.0, 1.0)
		update_building_progress(visible_after_progress)


func _ready() -> void:
	(get_parent() as BuildingVisualRoot).building_progress_updated.connect(update_building_progress)

func update_building_progress(progress_: float) -> void:
	progress = progress_
	self.visible = progress >= visible_after_progress
