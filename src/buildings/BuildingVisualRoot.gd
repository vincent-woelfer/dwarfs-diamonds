@tool
class_name BuildingVisualRoot
extends Node2D

var progress: float = 1.0

# Signal
signal building_progress_updated(new_progress: float)

########################################################################################################################
# DEV / EDITOR ONLY
########################################################################################################################
@export_range(0.0, 1.0, 0.1) var progress_preview: float = 1.0:
	set(value):
		progress_preview = clampf(value, 0.0, 1.0)
		update_building_progress(progress_preview)


########################################################################################################################
# Public API
########################################################################################################################
func update_building_progress(progress_: float) -> void:
	progress = clampf(progress_, 0.0, 1.0)

	building_progress_updated.emit(progress)

########################################################################################################################
# Internal API
########################################################################################################################
func _ready() -> void:
	if Engine.is_editor_hint():
		update_building_progress(progress_preview)
	else:
		update_building_progress(0.0)
