class_name BuildJob
extends AbstractJob

########################################################################################################################
# VARIABLES
########################################################################################################################
var building: Building


########################################################################################################################
# OVERRIDDEN PUBLIC METHODS
########################################################################################################################
func get_job_type_name() -> String:
	return "BUILD"


## Verifies that all required variables are set for this job
func verify_variables() -> void:
	assert(center_cell != null)
	assert(building != null)


## Generates the list of tasks required to complete this job.
func generate_tasks() -> Array[Task]:
	var tasks: Array[Task] = []

	tasks.append(Task.create_move_to_job_task(self))
	tasks.append(Task.create_construct_task(building.grid_pos, building))

	return tasks


## Number of dwarfs that can work on this job simultaneously
func calculate_dwarf_capacity() -> int:
	# Only allow multiple dwarfs for big buildings
	var is_big_building := building.building_data.build_time >= Building.BIG_BUILDING_TIME_THRESHOLD
	if is_big_building and building.build_progress == 0.0 and workable_from_poses.size() >= 2:
		return 2
	return 1


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

	return ScoredJob.new(self, path, score)


func update_workable_from_poses() -> void:
	var can_use_ladders: bool = true
	workable_from_poses.clear()

	for n_grid_pos: Vector2i in building.building_data.pattern_build_from.get_positions(building.grid_pos):
		var n_cell: Cell = Global.level.get_cell(n_grid_pos)

		if not n_cell or not n_cell.is_standable(can_use_ladders):
			continue

		workable_from_poses.append(n_cell.grid_pos)

	# For ladders, only allow building from outside center cell if it isnt possible from there.
	if building.building_data.type == Enum.BuildingType.LADDER:
		if building.grid_pos in workable_from_poses:
			workable_from_poses.clear()
			workable_from_poses.append(building.grid_pos)


## Estimates remaining time in seconds. For now only works when dwarf already arrived at job.
## Used for other dwarfs to decide whether to take this job or not.
func estimate_remaining_time() -> float:
	# Simple estimate based on job type
	var remaining_time: float = MAX_REMAINING_TIME_ESTIMATE

	if assigned_dwarfs.is_empty():
		return remaining_time

	for dwarf: Dwarf in assigned_dwarfs:
		# If at least one dwarf is already building -> use its speed
		if dwarf.sm.state == Dwarf.State.BUILDING:
			var build_time: float = dwarf.construction_comp.estimate_remaining_time_to_build(building)
			remaining_time = minf(remaining_time, build_time)

		# Dwarf still walking to job
		else:
			if dwarf.sm.state == Dwarf.State.MOVING:
				var walk_time: float = dwarf.movement_comp.get_remaining_path_time()
				var build_time: float = dwarf.construction_comp.estimate_remaining_time_to_build(building)
				remaining_time = minf(remaining_time, walk_time + build_time)

	return remaining_time


func can_dwarf_do_job_at_all(dwarf: Dwarf) -> bool:
	return dwarf.construction_comp.can_build_at_all(building)


## Checks whether this job is a duplicate of another job (by data, not by reference)
func is_duplicate(other_job: AbstractJob) -> bool:
	# Casting with "as" returns null if it fails
	var other_build_job: BuildJob = other_job as BuildJob
	if other_build_job == null:
		return false

	if building != other_build_job.building:
		return false

	return true


########################################################################################################################
# INTERNAL METHODS
########################################################################################################################
func _init(building_: Building) -> void:
	assert(building_ != null)
	self.building = building_

	var cell: Cell = Global.level.get_cell(building.grid_pos)
	assert(cell != null)
	super(cell)
