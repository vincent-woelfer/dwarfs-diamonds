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
	EventBus.Signal_CellMiningCompleted.emit(cell)

	# Call global action to trigger all steps
	Actions.mark_cell_for_mining(cell, false)

	# Spawn Rubble
	# Global.level.spawn_rubble(cell.grid_pos)


func mark_cell_for_mining(cell: Cell, is_marked_for_mining: bool) -> void:
	var changed := cell.set_marked_for_mining(is_marked_for_mining)
	if not changed:
		return

	# Add or remove mining job
	if cell.is_marked_for_mining:
		Global.level.job_manager.add_job(Job.new(Job.Type.MINE, cell))
	else:
		Global.level.job_manager.remove_mining_job_for_cell(cell)
