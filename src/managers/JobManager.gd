class_name JobManager
extends Node2D

var _jobs: Array[Job] = [] # Ensure Job class is properly defined elsewhere

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
					assert(false, "JobManager: Not adding duplicate pickup job for object %s" % job.carryable_item.parent)
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
func get_new_job_for_dwarf(dwarf: Dwarf) -> JobWithPath:
	assert(dwarf != null)
	var start_pos: Vector2i = dwarf.grid_pos
	var print_color := Colors.to_print_color(dwarf.dwarf_color)

	# Check if we are in a connected cell
	if not Global.level.nav_manager.is_cell_enabled(start_pos):
		HexLog.print_throttled(dwarf, "%s is in a disconnected cell, pathfinding is disabled!" % [dwarf])
		return null

	# Update all jobs first
	# TODO benchmark this, if it becomes a bottleneck we can add a dirty flag to only update when needed
	for job in _jobs:
		job.update_workable_from_cells()

	# Filter jobs and score all remaining jobs according to various criteria (mostly distance for now)
	var workable_jobs: Array[Job] = _filter_workable_jobs_for_dwarf(dwarf)
	var scored_jobs: Array[ScoredJob] = []

	for job: Job in workable_jobs:
		var path: Path = Global.level.nav_manager.find_path_to_one_of(start_pos, job.workable_from_poses)
		if not path:
			continue

		var scored_job: ScoredJob = _score_job(job, path, dwarf)
		if scored_job != null:
			scored_jobs.append(scored_job)
		
	# No valid jobs -> Return null
	# Also, print all jobs, throttled AND only if we had any
	if scored_jobs.is_empty():
		if not _jobs.is_empty():
			if HexLog.print_throttled(dwarf, "\nJobManager: No valid job for %s, rejected jobs (means no path or not workable for this dwarf):" % [dwarf],
					Dwarf.NO_JOB_THROTTLED_PRINT_INTERVALL, print_color):
				for rejected_job: Job in _jobs:
					print_rich("- %s" % [rejected_job])
				# NO new-line as separator here, dwarf prints following line

		# Return no matter what since we found no valid job
		return null

	# Sort by score
	scored_jobs.sort_custom(ScoredJob.compare)

	# Debug Print	
	HexLog.print("\nJobManager: Scoring jobs for %s (lower is better):" % [dwarf], print_color)
	for scored_job: ScoredJob in scored_jobs:
		# Use print_rich to manually format color of score only
		print_rich(Util.color_string("- Score: %6.0f" % [scored_job.score], print_color) + (" - %s" % [scored_job.job]))
	print() # New line as separator

	# Return best job
	return JobWithPath.new(scored_jobs[0].job, scored_jobs[0].path)
	

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _ready() -> void:
	self.process_priority = Enum.ProcessPriority.JOBS
	EventBus.Signal_NavUpdated.connect(_on_nav_updated)


func _process(delta: float) -> void:
	# To many places, just call every frame. This is because the jobs themselfs can also change
	_debug_draw_proxy_relative.queue_redraw()


# Not really required, this only keeps jobs up to date for debug drawing
func _on_nav_updated() -> void:
	for job in _jobs:
		job.update_workable_from_cells()


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
				assert(dwarf.carry_comp != null)
				assert(job.carryable_item != null)
				if not dwarf.carry_comp.can_carry_ignoring_position(job.carryable_item):
					continue
		
		# Job is workable for this dwarf -> add to output
		filtered_jobs.append(job)

	return filtered_jobs


## Score job - lower is better
## Unit = world space distance (because path length is the default score)
## Returns null if job should not be considered at all
func _score_job(job: Job, path: Path, dwarf: Dwarf) -> ScoredJob:
	var walking_speed := dwarf.movement_comp.movement_capabilities.get_speed(Enum.MoveMode.WALK)
	
	var remaining_time := job.estimate_remaining_time()
	var path_length := path.get_total_length_world_space()
	var score: float = path_length

	# Dont start jobs that will be finished before we arrive
	if path_length / walking_speed > remaining_time:
		return null

	# Penalize jobs which are already being worked on / are close to being finished
	if remaining_time < Job.MAX_REMAINING_TIME_ESTIMATE:
		score += 2 * Global.CELL_SIZE

	# Penalize mining job directly below dwarf (only slightly, prefer horizontally adjacent ones)
	# This is to avoid dwarfs digging straight down below themselves too often
	if job.job_type == Job.Type.MINE:
		if dwarf.grid_pos == job.center_cell.grid_pos - Vector2i(0, 1):
			score += 1.0

	# Dont prioritize pickup jobs (unless same cell)
	if job.job_type == Job.Type.PICKUP and dwarf.grid_pos != job.center_cell.grid_pos:
		score += 2 * Global.CELL_SIZE

	return ScoredJob.new(job, path, score)

	
########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy_relative := DebugDrawProxy.new(self)

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


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toogle_jobs_draw"):
		_debug_draw_proxy_relative.visible = not _debug_draw_proxy_relative.visible
		_debug_draw_proxy_relative.queue_redraw()
