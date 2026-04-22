@tool
class_name BuildingVisualBase
extends Node2D

var building_visuals: Array[BuildingVisual] = []

var progress: float = -1.0

# Editable from editor
@export_range(0.0, 1.0, 0.1) var progress_preview: float = 1.0:
	set(value):
		progress_preview = clampf(value, 0.0, 1.0)
		update_building_progress(progress_preview)

func _ready() -> void:
	refresh_child_nodes()

	child_entered_tree.connect(refresh_child_nodes)
	child_exiting_tree.connect(refresh_child_nodes)

	if Engine.is_editor_hint():
		update_building_progress(progress_preview)
	else:
		update_building_progress(0.0)

	
func update_building_progress(new_progress: float) -> void:
	new_progress = clampf(new_progress, 0.0, 1.0)
	if new_progress == progress:
		return
	self.progress = new_progress

	for visual in building_visuals:
		visual.update_building_progress(progress)


func refresh_child_nodes() -> void:
	for child in get_children():
		if child is BuildingVisual:
			if child not in building_visuals:
				building_visuals.append(child)
				(child as BuildingVisual).update_building_progress(progress)
			else:
				building_visuals.erase(child)
