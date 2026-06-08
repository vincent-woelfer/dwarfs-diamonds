class_name GatherJob
extends AbstractJob

# Gather Job is a specifif set of items from ground and/or storage to be moved to a stockpile (for building construction).

########################################################################################################################
# VARIABLES
########################################################################################################################

########################################################################################################################
# PUBLIC METHODS with PER-JOB-TYPE LOGIC
########################################################################################################################
func get_job_type_name() -> String:
	var base_name: String = "GATHER"
	return base_name


## Verifies that all required variables are set for this job
func verify_variables() -> void:
	assert(center_cell != null)


## Generates the list of tasks required to complete this job.
func generate_tasks() -> Array[Task]:
	var tasks: Array[Task] = []

	# TODO
	# tasks.append(Task.create_move_to_job_task(self))
	# tasks.append(Task.create_pickup_task(item.grid_pos, item))

	return tasks


## Number of dwarfs that can work on this job simultaneously
func calculate_dwarf_capacity() -> int:
	return 1


func score_job_for_dwarf_with_path(dwarf: Dwarf, path: Path) -> ScoredJob:
	var path_time := path.get_total_time(dwarf.movement_comp.movement_stats)

	# Minimum score is 1.0, base score is path time.
	var score: float = 1.0 + path_time


	return ScoredJob.new(self, path, score)


func update_workable_from_poses() -> void:
	if item.can_be_picked_up_right_now():
		workable_from_poses = [item.grid_pos]
	else:
		workable_from_poses = []


## Estimates remaining time in seconds. For now only works when dwarf already arrived at job.
## Used for other dwarfs to decide whether to take this job or not.
func estimate_remaining_time() -> float:
	# Only one dwarf can do this job
	return AbstractJob.MAX_REMAINING_TIME_ESTIMATE


func can_dwarf_do_job_at_all(dwarf: Dwarf) -> bool:
	return dwarf.storage_comp.does_fit_into_capacity(item)


## Checks whether this job is a duplicate of another job (by data, not by reference)
func is_duplicate(other_job: AbstractJob) -> bool:
	var other_pickup_job: PickupJob = other_job as PickupJob
	if other_pickup_job == null:
		return false

	if item != other_pickup_job.item:
		return false

	return true


########################################################################################################################
# INTERNAL METHODS
########################################################################################################################
func _init(item_: Item) -> void:
	assert(item_ != null)
	self.item = item_

	var cell: Cell = Global.level.get_cell(item.grid_pos)
	assert(cell != null)
	super(cell)
