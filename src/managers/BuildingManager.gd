@tool
class_name BuildingManager
extends Node2D

var buildings: Array[Building] = []
var action_points: Array[ActionPoint] = []

########################################################################################################################
# BUILDINGS
########################################################################################################################
## Called by Building to add itself when created
func add_building(building: Building) -> void:
	if Engine.is_editor_hint(): return

	if building in buildings:
		push_error("BuildingManager: Trying to register building that is already registered: %s" % building)
		return

	buildings.append(building)
	add_child(building)


## Called by Building to unregister itself when removed (entering teardown state)
func teardown_building(building: Building) -> void:
	if Engine.is_editor_hint(): return

	if not building in buildings:
		push_error("BuildingManager: Trying to teardown building that is not registered: %s" % building)
		return

	if building.sm.state != Building.State.IN_TEARDOWN:
		push_error("BuildingManager: Trying to teardown building that is not in teardown state: %s" % building)
		return

	unregister_all_action_points(building)
	buildings.erase(building)
	

## Called by building itself to finally be removes from scene (after teardown effects are done)
func delete_building(building: Building) -> void:
	if Engine.is_editor_hint(): return

	if building == null:
		return

	if building.sm.state != Building.State.IN_TEARDOWN:
		push_error("BuildingManager: Trying to delete building that is not in teardown state: %s" % building)
		return

	assert(building.action_points.is_empty())
		
	remove_child(building)
	building.queue_free()

########################################################################################################################
# Action Points
########################################################################################################################
## Called by Building to register its action points
func register_action_points(building: Building, aps: Array[ActionPoint]) -> void:
	if Engine.is_editor_hint(): return

	if not building in buildings:
		push_error("BuildingManager: Trying to add APs for building that is not registered: %s" % building)
		return

	for ap: ActionPoint in aps:
		if ap in action_points:
			push_error("BuildingManager: Trying to register AP that is already registered: %s" % ap)
			continue

		action_points.append(ap)

		# Add to cell
		var cell: Cell = Global.level.get_cell(ap.grid_pos)
		if cell != null:
			cell.add_action_point(ap)

		# Add to building
		building.add_child(ap)


## 
func unregister_action_points(building: Building, aps: Array[ActionPoint]) -> void:
	for ap: ActionPoint in aps:
		if ap not in action_points:
			push_error("BuildingManager: Trying to unregister AP that is not registered: %s" % ap)
			continue

		if ap not in building.action_points:
			push_error("BuildingManager: Trying to unregister AP that is not part of building's APs: %s" % ap)
			continue
	
		_delete_ap(ap, building)


func unregister_all_action_points(building: Building) -> void:
	unregister_action_points(building, building.action_points)
		
###################################
# Fetching Data
###################################
func get_all_action_points(type: ActionPoint.ApType) -> Array[ActionPoint]:
	if Engine.is_editor_hint(): return []

	var filtered_aps: Array[ActionPoint] = []
	for ap: ActionPoint in action_points:
		# Check type
		if ap.type != type:
			continue

		# Check if active
		if not ap.is_active:
			continue

		# Verify that the cell is enabled in nav-mesh
		var cell: Cell = Global.level.get_cell(ap.grid_pos)
		if cell == null or not Global.level.nav_manager.is_cell_enabled(ap.grid_pos):
			continue

		# Verify its available for interaction


		# Finally add
		filtered_aps.append(ap)

	return filtered_aps


########################################################################################################################
# Private Methods
########################################################################################################################
func _delete_ap(ap: ActionPoint, building: Building) -> void:
	assert(ap != null)

	action_points.erase(ap)

	# Remove from cell
	var cell: Cell = Global.level.get_cell(ap.grid_pos)
	if cell != null:
		cell.remove_action_point(ap)

	# Remove from scene
	building.remove_child(ap)
	ap.queue_free()
