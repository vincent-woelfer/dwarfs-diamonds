class_name JobManager
extends Node2D

var _jobs: Array[Job] = [] # Ensure Job class is properly defined elsewhere

const max_fall_height_for_job_application: int = 2

########################################################################################################################
# PUBLIC METHODS - ADD / REMOVE JOBS
########################################################################################################################
func add_job(job: Job) -> void:
	assert(job != null)
	assert(job not in _jobs)
	assert(job.center_cell != null)
	assert(job.is_active)

	match job.job_type:
		Job.Type.MINE:
			for existing_job in _jobs:
				if existing_job.job_type == Job.Type.MINE and existing_job.center_cell == job.center_cell:
					assert(false, "JobManager: Not adding duplicate mining job for cell %s" % job.center_cell)
					return

		Job.Type.BUILD:
			assert(job.building != null)
			for existing_job in _jobs:
				if existing_job.job_type == Job.Type.BUILD and existing_job.building == job.building:
					assert(false, "JobManager: Not adding duplicate build job for building %s" % job.building)
					return

		Job.Type.PICKUP:
			assert(job.carryable_item != null)
			for existing_job in _jobs:
				if existing_job.job_type == Job.Type.PICKUP and existing_job.carryable_item == job.carryable_item:
					assert(false, "JobManager: Not adding duplicate pickup job for object %s" % job.carryable_item)
					return
	

	job.update_workable_from_cells()
	_jobs.append(job)


## ONLY called by global actions when archiving a job
func remove_job(job: Job) -> void:
	if job == null:
		return

	# Must be archived beforehand
	assert(job.is_active == false)
	assert(job in _jobs)

	_jobs.erase(job)


# Called by Global Action if cell is no longer marked for mining
func remove_mining_job_for_cell(cell: Cell) -> void:
	for job in _jobs:
		if job.job_type == Job.Type.MINE and job.center_cell == cell:
			Actions.archive_job(job, false)
			return

########################################################################################################################
# PUBLIC METHODS - GET NEW JOB FOR DWARF
########################################################################################################################

## Get best job for dwarf according to various criteria
## THE MAIN FUNCTION OF THE JOB MANAGER
func apply_for_new_job(dwarf: Dwarf) -> bool:
	assert(dwarf != null)

	if not Global.level.nav_manager.is_cell_enabled(dwarf.grid_pos):
		HexLog.throttled(dwarf, "%s is in a disconnected cell, pathfinding is disabled, not accepting job application!" % [dwarf])
		return false

	if dwarf in _dwarfs_looking_for_jobs:
		print_rich("%s is already looking for a job, ignoring duplicate apply!" % [dwarf])
		return false

	if _jobs.is_empty():
		return false

	_dwarfs_looking_for_jobs.append(dwarf)
	return true


## Used by JobDistributionHandler
## Gathers alls workable jobs and scores them
func score_jobs_for_dwarf(dwarf: Dwarf) -> Array[ScoredJob]:
	var start_pos: Vector2i = dwarf.grid_pos

	if dwarf.sm.state == Dwarf.State.FALLING and dwarf.est_fall_height_cells <= max_fall_height_for_job_application:
		start_pos = dwarf.est_landing_cell.grid_pos

	if not Global.level.nav_manager.is_cell_enabled(start_pos):
		return []

	# Filter jobs and score all remaining jobs according to various criteria (mostly distance for now)
	var workable_jobs: Array[Job] = _filter_workable_jobs_for_dwarf(dwarf)
	var scored_jobs: Array[ScoredJob] = []

	for job: Job in workable_jobs:
		var path: Path = Global.level.nav_manager.find_path_to_one_of(start_pos, job.workable_from_poses, dwarf.movement_comp.movement_stats)
		if not path:
			continue

		var scored_job: ScoredJob = _score_job(job, path, dwarf)
		if scored_job != null:
			scored_jobs.append(scored_job)
		
	# Sort by score
	scored_jobs.sort_custom(ScoredJob.compare)

	# Debug Print
	# if not scored_jobs.is_empty():
	# var print_color := Colors.to_print_color(dwarf.dwarf_color)
	# HexLog.print("\nJobManager: Scoring jobs for %s (lower is better):" % [dwarf], print_color)
	# for scored_job: ScoredJob in scored_jobs:
	# 	# Use print_rich to manually format color of score only
	# 	print_rich(Util.color_string("- Score: %6.1f" % [scored_job.score], print_color) + (" - %s" % [scored_job.job]))
	# print() # New line as separator

	# Return job
	return scored_jobs


## Registers dwarf as looking for a job this frame
var _dwarfs_looking_for_jobs: Array[Dwarf] = []

## Main job distribution function
func _distribute_jobs_to_dwarfs() -> void:
	var start_time := Time.get_ticks_msec()

	# Add soon-landing dwarfs as dummy applicants so other dwarfs do not get their most obvious jobs in the landing cell
	for dwarf in Global.level.dwarfs:
		if dwarf.sm.state == Dwarf.State.FALLING and dwarf.est_fall_height_cells <= max_fall_height_for_job_application:
			if dwarf not in _dwarfs_looking_for_jobs:
				_dwarfs_looking_for_jobs.append(dwarf)

	if _dwarfs_looking_for_jobs.is_empty() or _jobs.is_empty():
		_dwarfs_looking_for_jobs.clear()
		return

	# Update all jobs first
	for job in _jobs:
		job.update_workable_from_cells()

	# HexLog.print("Jobs  => Starting job distribution to %d dwarfs..." % [_dwarfs_looking_for_jobs.size()], Colors.JOBS_PRINT_COLOR)
	var job_distribution_handler: JobDistributionHandler = JobDistributionHandler.new()
	var dwarf_jobs_assignment := job_distribution_handler.distribute_jobs(_dwarfs_looking_for_jobs)
	_dwarfs_looking_for_jobs.clear()

	# Assign jobs to dwarfs
	for i in range(dwarf_jobs_assignment.total_size):
		var dwarf: Dwarf = dwarf_jobs_assignment.dwarfs[i]
		var job: Job = dwarf_jobs_assignment.jobs[i]

		# Assign null aswell (means no job assigned, none available)
		dwarf._on_job_assigned(job)


	var duration := Time.get_ticks_msec() - start_time
	if dwarf_jobs_assignment.total_assigned_jobs > 0:
		HexLog.print("Jobs  => Distributed %d jobs to %d dwarfs in: %d ms" % [dwarf_jobs_assignment.total_assigned_jobs, dwarf_jobs_assignment.total_size, duration], Colors.JOBS_PRINT_COLOR)


########################################################################################################################
# Job Filtering and Scoring
########################################################################################################################
func _filter_workable_jobs_for_dwarf(dwarf: Dwarf) -> Array[Job]:
	var filtered_jobs: Array[Job] = []
	for job: Job in _jobs:
		if not job.is_workable():
			continue

		# Check if this dwarf / their components have the capabilities to do this job at all
		match job.job_type:
			Job.Type.MINE:
				assert(dwarf.mining_comp != null)
				assert(job.center_cell != null)
				if not dwarf.mining_comp.can_mine_at_all(job.center_cell):
					continue

			Job.Type.BUILD:
				assert(dwarf.construction_comp != null)
				assert(job.building != null)
				if not dwarf.construction_comp.can_build_at_all(job.building):
					continue

			Job.Type.PICKUP:
				assert(dwarf.storage_comp != null)
				assert(job.carryable_item != null)
				if not dwarf.storage_comp.does_fit_into_capacity(job.carryable_item):
					continue
		
		# Job is workable for this dwarf -> add to output
		filtered_jobs.append(job)

	return filtered_jobs


## Score job - lower is better.
## Unit = seconds (because path time is the default score).
## Returns null if job should not be considered at all
func _score_job(job: Job, path: Path, dwarf: Dwarf) -> ScoredJob:
	var remaining_time := job.estimate_remaining_time()
	var path_time := path.get_total_time(dwarf.movement_comp.movement_stats)

	# Minimum score is 1.0, base score is path time.
	var score: float = 1.0 + path_time

	# Dont start jobs that will be finished before we arrive
	if path_time > remaining_time:
		return null

	# Penalize jobs which are already being worked on / are close to being finished
	if remaining_time < Job.MAX_REMAINING_TIME_ESTIMATE:
		score += 5.0

	# Penalize mining job directly below dwarf (only slightly, prefer horizontally adjacent ones)
	# This is to avoid dwarfs digging straight down below themselves too often
	if job.job_type == Job.Type.MINE:
		if dwarf.grid_pos == job.center_cell.grid_pos - Vector2i(0, 1):
			score += 1.0

	# PICKUP
	if job.job_type == Job.Type.PICKUP:
		# Dont prioritize rubble pickup jobs (unless same cell)
		if dwarf.grid_pos != job.center_cell.grid_pos:
			score += 2.0

		# Prioritize gemstones over rubble
		if job.carryable_item.item_type == Enum.ItemType.GEMSTONE:
			score *= 0.5

	return ScoredJob.new(job, path, score)

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _ready() -> void:
	self.process_priority = Enum.ProcessPriority.JOBS

	# Signals
	EventBus.Signal_NavUpdated.connect(_on_nav_updated)

	# Dev Signals
	EventBus.Signal_DevToogleJobsDraw.connect(_dev_toogle_jobs_draw)
	_dev_toogle_jobs_draw()


func _process(delta: float) -> void:
	# To many places, just call every frame. This is because the jobs themselfs can also change
	_debug_draw_proxy_relative.queue_redraw()

	_distribute_jobs_to_dwarfs()


# Not really required, this only keeps jobs up to date for debug drawing
func _on_nav_updated() -> void:
	for job in _jobs:
		job.update_workable_from_cells()
	
########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy_relative := DebugDrawProxy.new(self )

# Multiple jobs per cell are placed from top to bottom with an offset
const debug_offset_start := Vector2(-0.44, -0.35) * Global.CELL_SIZE_VEC
const debug_offset_inc := Vector2(0.0, 0.12) * Global.CELL_SIZE_VEC

var debug_font := ThemeDB.fallback_font
var debug_font_size := 14

func _debug_draw_in_ui_relative(ui_layer: CanvasItem) -> void:
	var num_already_drawn_per_cell: Dictionary[Vector2i, int] = {}

	for job in _jobs:
		var cell: Cell = job.center_cell

		var draw_world_pos := Util.grid_to_world_cell_center(cell.grid_pos)
		var offset_idx: int = num_already_drawn_per_cell.get(cell.grid_pos, 0)
		num_already_drawn_per_cell[cell.grid_pos] = offset_idx + 1
		var pos := draw_world_pos + _debug_get_offset(offset_idx)

		# Job Info
		var info := job.get_debug_info()
		var text: String = info[0] + " - " + info[1]
		var color: Color = info[2]

		ui_layer.draw_string(debug_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, debug_font_size, color)


## Get offset for each text entry to avoid overlapping
func _debug_get_offset(idx: int) -> Vector2:
	return debug_offset_start + debug_offset_inc * idx


func _dev_toogle_jobs_draw() -> void:
	_debug_draw_proxy_relative.visible = EventBus.dev_draw_jobs
	_debug_draw_proxy_relative.queue_redraw()
