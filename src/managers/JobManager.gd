class_name JobManager
extends Node2D

var _jobs: Array[Job] = []

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func add_job(job: Job) -> void:
	assert(job != null)

	# Prevent duplicate mining jobs for same cell
	if job.job_type == Job.Type.MINE:
		for existing_job in _jobs:
			if existing_job.job_type == Job.Type.MINE and existing_job.center_cell == job.center_cell:
				assert(false, "JobManager: Not adding duplicate mining job for cell " % job.center_cell)
				return

	# Prevent duplicate build jobs for same building
	if job.job_type == Job.Type.BUILD:
		assert(job.building != null)

		for existing_job in _jobs:
			if existing_job.job_type == Job.Type.BUILD and existing_job.building == job.building:
				assert(false, "JobManager: Not adding duplicate build job for building " % job.building)
				return

	# Prevent duplicate rubble jobs for same rubble
	if job.job_type == Job.Type.RUBBLE:
		assert(job.rubble != null)

		for existing_job in _jobs:
			if existing_job.job_type == Job.Type.RUBBLE and existing_job.rubble == job.rubble:
				assert(false, "JobManager: Not adding duplicate rubble job for rubble " % job.rubble)
				return
	

	job.update_workable_from_cells()
	_jobs.append(job)


func remove_job(job: Job) -> void:
	if job == null:
		return
		
	assert(job in _jobs)

	job.delete()
	_jobs.erase(job)


# Called by Global Action if cell is no longer marked for mining
func remove_mining_job_for_cell(cell: Cell) -> void:
	for job in _jobs:
		if job.job_type == Job.Type.MINE and job.center_cell == cell:
			job.delete()
			_jobs.erase(job)
			return


func get_new_job_for_worker(dwarf: Dwarf) -> JobWithPath:
	assert(dwarf != null)
	var start_pos: Vector2i = dwarf.grid_pos

	# Check if we are in a connected cell
	if not Global.level.nav_manager.is_cell_enabled(start_pos):
		HexLog.print_throttled(dwarf, "%s is in a disconnected cell, pathfinding is disabled!" % [dwarf])
		return null

	var walking_speed := dwarf.movement_comp.movement_capabilities.get_speed(Enum.MoveMode.WALK)

	# Update all jobs first
	for job in _jobs:
		job.update_workable_from_cells()


	# Score all jobs according to various criteria (mostly distance for now)
	var scored_jobs: Array[ScoredJob] = []

	for job: Job in _jobs:
		if not job.is_workable():
			continue

		var path: Path = Global.level.nav_manager.find_path_to_one_of(start_pos, job.workable_from_poses)
		if not path:
			continue

		###################################
		### Score job - lower is better ###
		### Unit = world space distance (because path length is the default score)
		###################################
		var remaining_time := job.estimate_remaining_time()
		var path_length := path.get_total_length_world_space()
		var score: float = path_length

		# Dont start jobs that will be finished when we arrive
		if path_length / walking_speed > remaining_time:
			continue

		# Penalize jobs which are already being worked on / are close to being finished
		if remaining_time < Job.MAX_REMAINING_TIME_ESTIMATE:
			score += 2 * Global.CELL_SIZE

		# Penalize mining job directly below dwarf (only slightly, prefer horizontally adjacent ones)
		# This is to avoid dwarfs digging straight down below themselves too often
		if job.job_type == Job.Type.MINE:
			if dwarf.grid_pos == job.center_cell.grid_pos - Vector2i(0, 1):
				score += 1.0

		# Dont prioritize rubble/pickup jobs
		if job.job_type == Job.Type.RUBBLE:
			score += 2 * Global.CELL_SIZE

		scored_jobs.append(ScoredJob.new(job, path, score))

	# No valid jobs
	if scored_jobs.is_empty():
		return null

	# Sort by score
	scored_jobs.sort_custom(ScoredJob.compare)

	# Debug Print
	var print_color := Colors.to_print_color(dwarf.dwarf_color)
	print_rich(Util.color_string("\nJobManager: Scoring jobs for %s (lower is better):" % [dwarf], print_color))
	for j in scored_jobs:
		print_rich(Util.color_string("- Score: %6.0f" % [j.score], print_color) + (" - %s" % [j.job]))
	print() # New line as separator

	return JobWithPath.new(scored_jobs[0].job, scored_jobs[0].path)
	

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _init() -> void:
	self.process_priority = Enum.ProcessPriority.JOBS


func _ready() -> void:
	EventBus.Signal_NavUpdated.connect(_on_nav_updated)


func _process(delta: float) -> void:
	# To many places, just call every frame. This is because the jobs themselfs can also change
	_debug_draw_proxy_relative.queue_redraw()


# Not really required, this only keeps jobs up to date for debug drawing
func _on_nav_updated() -> void:
	for job in _jobs:
		job.update_workable_from_cells()

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
