@tool
class_name BuildingVisualRoot
extends Node2D

# scanned children - only those with update_building_progress method are stored and updated
var _building_visuals: Array[Node2D] = []
var _progress: float = 1.0

## Called on visual children via duck typing.
var _update_function_name: StringName = "update_building_progress"

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
func update_building_progress(new_progress: float) -> void:
	new_progress = clampf(new_progress, 0.0, 1.0)
	if new_progress == _progress:
		return
	self._progress = new_progress

	for visual in _building_visuals:
		visual.call(_update_function_name, _progress)
		# visual.update_building_progress(_progress)


########################################################################################################################
# Internal API
########################################################################################################################
func _ready() -> void:
	refresh_all_child_nodes()

	child_entered_tree.connect(refresh_child_node)
	child_exiting_tree.connect(refresh_child_node)

	if Engine.is_editor_hint():
		update_building_progress(progress_preview)
	else:
		update_building_progress(0.0)


## Only check changed node
func refresh_child_node(changed_node: Node) -> void:
	if changed_node.has_method(_update_function_name):
		# Check if should be added or removed
		if changed_node in get_children():
			# Only add if not already in the list BUT always update progress
			if changed_node not in _building_visuals:
				_building_visuals.append(changed_node)

			changed_node.call(_update_function_name, _progress)
			# changed_node.update_building_progress(_progress)
		else:
			_building_visuals.erase(changed_node)
			
	
## Clear and add all children anew
func refresh_all_child_nodes(changed_node: Node = null) -> void:
	_building_visuals.clear()
	for child in get_children():
		if child.has_method(_update_function_name):
			_building_visuals.append(child)

			child.call(_update_function_name, _progress)
			# child.update_building_progress(_progress)
