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

# Normally called by MiningComponent
func destroy_cell(cell: Cell) -> void:
	cell.destroy()

	# Signal MiningComponets that mining was completed
	EventBus.Signal_GlobalCellDestroyed.emit(cell)

	# Call global action to trigger all steps
	Actions.mark_cell_for_mining(cell, false)

	# Spawn Rubble
	Global.level.spawn_rubble(cell.grid_pos)


func mark_cell_for_mining(cell: Cell, is_marked_for_mining: bool) -> void:
	var changed := cell.set_marked_for_mining(is_marked_for_mining)
	if not changed:
		return

	# Add or remove mining job
	if cell.is_marked_for_mining:
		Global.level.job_manager.add_job(Job.new(Job.Type.MINE, cell))
	else:
		Global.level.job_manager.remove_mining_job_for_cell(cell)

	cell.visual.set_dirty()


func place_building(cell: Cell, building_data: BuildingData) -> BuildingBase:
	# TODO verify building can be placed (enough space, valid terrain, etc)
	print_rich("Placing building: %s at %s" % [building_data.name, cell.grid_pos])

	var building_instance := building_data.instantiate_scene() as BuildingBase
	building_instance.setup_building(cell.grid_pos, building_data)

	# Also adds as child
	Global.level.building_manager.register_building(building_instance)

	cell.add_building(building_instance)
	return building_instance
