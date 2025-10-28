class_name JobManager
extends Node2D

var _jobs: Array[Job] = []
var _debug_draw_proxy := DebugDrawProxy.new(self)


########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func add_job(job: Job) -> void:
	assert(job != null)

	# Prevent duplicate mining jobs for same cell
	if job.type == Job.Type.MINE:
		for existing_job in _jobs:
			if existing_job.type == Job.Type.MINE and existing_job.target_cell == job.target_cell:
				assert(false, "JobManager: Not adding duplicate mining job for cell " % job.target_cell.grid_pos)
				return

	_jobs.append(job)


# Called by Global Action if cell is no longer marked for mining
func remove_mining_job_for_cell(cell: Cell) -> void:
	for job in _jobs:
		if job.type == Job.Type.MINE and job.target_cell == cell:
			job.delete()
			_jobs.erase(job)
			return


func get_new_job_for_worker(start_pos: Vector2i) -> JobWithPath:
	# Filter for ready jobs
	var ready_jobs: Array[Job] = _jobs.filter(func(j: Job) -> bool:
		return j.status == Job.Status.READY
	)

	# Find job with shortest path
	var best_job_with_path: JobWithPath = null
	for job in ready_jobs:
		var path: Path = Global.level.nav.find_path_to_one_of(start_pos, job.workable_from_grid_poses)
		if path != null:
			if best_job_with_path == null or path.get_num_cells() < best_job_with_path.path.get_num_cells():
				best_job_with_path = JobWithPath.new(job, path)
			
	return best_job_with_path

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _init() -> void:
	self.process_priority = Enum.ProcessPriority.JOBS


func _ready() -> void:
	EventBus.Signal_NavUpdated.connect(_on_nav_updated)


func _process(delta: float) -> void:
	# To many places, just call every frame. This is because the jobs themselfs can also change
	_debug_draw_proxy.queue_redraw()


func _on_nav_updated() -> void:
	# Update all jobs not in progress
	for job in _jobs:
		if job.status != Job.Status.IN_PROCESS:
			job.update_workable_from_cells()
			job.update_status()

	
########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
const debug_status_colors := {
	Job.Status.BLOCKED: Color.RED,
	Job.Status.READY: Color.GREEN,
	Job.Status.IN_PROCESS: Color.BLUE,
}

const debug_size_point := 7.0

const debug_offset_start := Vector2(-0.44, -0.38) * Global.CELL_SIZE_VEC
const debug_offset_inc := Vector2(0.0, 0.12) * Global.CELL_SIZE_VEC

var debug_font := ThemeDB.fallback_font
var debug_font_size := 14

func _debug_draw_in_ui(ui_layer: CanvasItem) -> void:
	var num_already_drawn_per_cell: Dictionary[Vector2i, int] = {}

	for job in _jobs:
		var color_actual: Color = debug_status_colors.get(job.status, Colors.DEFAULT)
		var cell: Cell = job.target_cell

		var draw_world_pos := Util.grid_to_world_cell_center(cell.grid_pos)
		var offset_idx: int = num_already_drawn_per_cell.get(cell.grid_pos, 0)
		num_already_drawn_per_cell[cell.grid_pos] = offset_idx + 1

		var text: String = Enum.to_str(Job.Type, job.type) + " - " + Enum.to_str(Job.Status, job.status)
		var pos := draw_world_pos + _debug_get_offset(offset_idx)

		ui_layer.draw_string(debug_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, debug_font_size, color_actual)


func _debug_get_offset(idx: int) -> Vector2:
	return debug_offset_start + debug_offset_inc * idx


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toogle_jobs_draw"):
		_debug_draw_proxy.visible = not _debug_draw_proxy.visible
		_debug_draw_proxy.queue_redraw()
