# No class_name here, the name of the singleton is set in the autoload
extends Node2D

########################################################################################################################
# GLOBAL GAME ACTIONS
########################################################################################################################
# These are called from various places to trigger actions involving multiple steps.
# Instead of signals they coordinate the order of steps directly.
# This is to avoid complex signal chains and ordering issues.
# 
# If the order doesnt matter and its only simple notifications, use signals instead.
########################################################################################################################

func destroy_cell(cell: Cell) -> void:
	assert(cell != null)

	print_action("Destroying cell %s" % [cell])

	Global.level.level_stats_manager.total_mined_cells += 1

	cell.destroy_cell()

	Global.level.queue_update_cell_light_depth(cell.grid_pos)

	# Signal MiningComponets that mining was completed
	EventBus.Signal_CellDestroyed.emit(cell)

	# Call global action to trigger all steps (including job archiving)
	Actions.mark_cell_for_mining(cell, false)


func mark_cell_for_mining(cell: Cell, is_marked_for_mining: bool) -> void:
	var has_changed := cell.set_marked_for_mining(is_marked_for_mining)
	if not has_changed:
		return

	# Add or remove mining job
	if cell.is_marked_for_mining:
		Global.level.job_manager.add_job(Job.new(Job.Type.MINE, cell))
	else:
		Global.level.job_manager.remove_mining_job_for_cell(cell)

	cell.visual.set_dirty()


## Verification takes place before calling this
func place_building(cell: Cell, building_data: BuildingDataRes, finish_instantly: bool = false) -> Building:
	# Validate - actual validation already took place, just to catch any issues here
	assert(cell != null)
	assert(building_data != null)
	assert(PlacementChecks.is_placeable_at(building_data, cell.grid_pos))

	# Log
	var finish_instant_string := " (instantly)" if finish_instantly else ""
	print_action("Placing building: %s at %s%s" % [building_data.name, cell.grid_pos, finish_instant_string])

	# Instantiate building
	var building_instance: Building = Building.new()
	building_instance.setup_building(building_data.type, cell.grid_pos)

	if finish_instantly:
		building_instance.starting_state = Building.State.OPERATING

	# Play sound effect
	Audio.play_at_pos("building_placed", building_instance.global_position)

	# Also adds as child
	Global.level.building_manager.register_building(building_instance)

	# Add to all cells covered by building -> this updates their navmesh
	for pos in building_instance.building_data.pattern_building.get_positions(cell.grid_pos):
		var covered_cell: Cell = Global.level.get_cell(pos)
		assert(covered_cell != null) # This should never happen
		covered_cell.add_building(building_instance)

	return building_instance


func remove_building(building: Building) -> void:
	# Validate - actual validation already took place, just to catch any issues here
	assert(building != null)

	# Log
	var building_status: String = Enum.to_str(building.State, building.sm.state)
	print_action("Removing building: %s at %s (was %s)" % [building.building_data.name, building.grid_pos, building_status])

	# Call building destroy logic
	building.destroy()

	# Unregister building (not usable after this but still exists for visual effects)
	Global.level.building_manager.unregister_building(building)

	# Remove from all cells covered by building -> updates their navmesh
	for pos in building.building_data.pattern_building.get_positions(building.grid_pos):
		var covered_cell: Cell = Global.level.get_cell(pos)
		if covered_cell != null:
			covered_cell.remove_building(building)


func archive_job(job: Job, success: bool) -> void:
	# Ensure this is only triggered once
	if job == null or not job.is_active:
		return

	# Print before actually calling archive so log order makes more sense. This has the downside that the pinted job is still printed as active.
	if success:
		print_action("Completing successful job %s" % [job])
	else:
		print_action("Deleting aborted job %s" % [job])

	# Signals all dwarfs to call on_job_finished().
	# ONLY place where job.archive() is called.
	job.archive_internal(success)

	# This requires is_active=false
	Global.level.job_manager.remove_job(job)


########################################################################################################################
# PRINT UTILS
########################################################################################################################
func print_action(text: String) -> void:
	HexLog.print("ACTION => " + text, Colors.GLOBAL_ACTION_PRINT_COLOR)
