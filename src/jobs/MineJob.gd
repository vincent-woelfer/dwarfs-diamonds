class_name MineJob
extends AbstractJob

########################################################################################################################
# VARIABLES
########################################################################################################################
# none

########################################################################################################################
# OVERRIDDEN PUBLIC METHODS
########################################################################################################################
func get_job_type_name() -> String:
	return "MINE"


## Verifies that all required variables are set for this job
func verify_variables() -> void:
	assert(center_cell != null)


## Generates the list of tasks required to complete this job.
func generate_tasks() -> Array[Task]:
	var tasks: Array[Task] = []
	tasks.append(Task.create_move_to_job_task(self))
	tasks.append(Task.create_mine_task(center_cell.grid_pos))
	return tasks


## Number of dwarfs that can work on this job simultaneously
func calculate_dwarf_capacity() -> int:
	# Up to 2 dwarfs can mine simultaneously (if enough space)
	return mini(2, workable_from_poses.size())


func score_job_for_dwarf_with_path(dwarf: Dwarf, path: Path) -> ScoredJob:
	var remaining_time := estimate_remaining_time()
	var path_time := path.get_total_time(dwarf.movement_comp.movement_stats)

	# Minimum score is 1.0, base score is path time.
	var score: float = 1.0 + path_time

	# Dont start jobs that will be finished before we arrive
	if path_time > remaining_time:
		return null

	# Penalize jobs which are already being worked on / are close to being finished
	if assigned_dwarfs.size() > 0:
		score += 10.0

	# Penalize mining job directly below dwarf (only slightly, prefer horizontally adjacent ones)
	# This is to avoid dwarfs digging straight down below themselves too often
	if dwarf.grid_pos == center_cell.grid_pos - Vector2i(0, 1):
		score += 1.0

	return ScoredJob.new(self, path, score)


func update_workable_from_poses() -> void:
	var can_use_ladders: bool = true
	workable_from_poses.clear()

	for n_offset: Vector2i in Util.neighbours_cardinal:
		var n_cell: Cell = center_cell.get_neighbour(n_offset)

		if not n_cell or not n_cell.is_standable(can_use_ladders):
			continue

		workable_from_poses.append(n_cell.grid_pos)


## Estimates remaining time in seconds. For now only works when dwarf already arrived at job.
## Used for other dwarfs to decide whether to take this job or not.
func estimate_remaining_time() -> float:
	var remaining_time: float = MAX_REMAINING_TIME_ESTIMATE

	if assigned_dwarfs.is_empty():
		return remaining_time

	for dwarf: Dwarf in assigned_dwarfs:
		# If at least one dwarf is already mining -> use its speed
		if dwarf.sm.state == Dwarf.State.MINING:
			var mine_time: float = dwarf.mining_comp.estimate_remaining_time_to_mine_cell(center_cell)
			remaining_time = minf(remaining_time, mine_time)

		# Dwarf still walking to job
		else:
			if dwarf.curr_path:
				var walk_time: float = dwarf.movement_comp.get_remaining_path_time()
				var mine_time: float = dwarf.mining_comp.estimate_remaining_time_to_mine_cell(center_cell)
				remaining_time = minf(remaining_time, walk_time + mine_time)

	return remaining_time


func can_dwarf_do_job_at_all(dwarf: Dwarf) -> bool:
	return dwarf.mining_comp.can_mine_at_all(center_cell)


## Checks whether this job is a duplicate of another job (by data, not by reference)
func is_duplicate(other_job: AbstractJob) -> bool:
	# Casting with "as" returns null if it fails
	var other_mine_job: MineJob = other_job as MineJob
	if other_mine_job == null:
		return false

	if center_cell != other_mine_job.center_cell:
		return false

	return true


########################################################################################################################
# INTERNAL METHODS
########################################################################################################################
func _init(cell_: Cell) -> void:
	super(cell_)
