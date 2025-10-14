class_name JobManager
extends Node2D

var _jobs: Array[Job] = []


########################################################################
# PUBLIC METHODS
########################################################################
func add_job(job: Job) -> void:
	assert(job != null)

	if job.type == Job.Type.MINE:
		for existing_job in _jobs:
			if existing_job.type == Job.Type.MINE and existing_job.cell == job.cell:
				print("JobManager: Not adding duplicate mining job for cell ", job.cell.grid_pos)
				return

	_jobs.append(job)
	queue_redraw()


func remove_mining_job_for_cell(cell: Cell) -> void:
	for job in _jobs:
		if job.type == Job.Type.MINE and job.cell == cell:
			_jobs.erase(job)
			queue_redraw()
			return


########################################################################
# PRIVATE METHODS
########################################################################
func _init() -> void:
	self.process_priority = Enum.ProcessPriority.JOBS


func _ready() -> void:
	EventBus.Signal_NavUpdated.connect(_on_nav_updated)


func _process(delta: float) -> void:
	pass


func _on_nav_updated() -> void:
	# Update status of all jobs
	for job in _jobs:
		job.update_workable_from_cells()

	queue_redraw()
	

########################################################################
# DEBUG DRAWING
########################################################################
var debug_show := true
# const debug_color_mine := Color(0.0, 1.0, 0.0)
# const debug_color_build := Color(0.0, 1.0, 0.4)
# const debug_color_carry := Color(1.0, 0.8, 0.0)
const debug_color_blocked := Color.RED
const debug_color_ready := Color.GREEN
const debug_color_in_progress := Color.PURPLE

const debug_size_point := 7.0

const debug_offset_start := Vector2(-0.44, -0.38) * Global.CELL_SIZE_VEC
const debug_offset_inc := Vector2(0.0, 0.12) * Global.CELL_SIZE_VEC

var debug_font := ThemeDB.fallback_font
var debug_font_size := 14

func _draw() -> void:
	if not debug_show:
		return

	var num_already_drawn_per_cell: Dictionary[Vector2i, int] = {}

	for job in _jobs:
		var color_actual: Color
		match job.status:
			Job.Status.BLOCKED:
				color_actual = debug_color_blocked
			Job.Status.READY:
				color_actual = debug_color_ready
			Job.Status.IN_PROCESS:
				color_actual = debug_color_in_progress

		var cell: Cell = job.cell

		var draw_world_pos := Util.grid_space_to_world_space_cell_center(cell.grid_pos)
		var offset_idx: int = num_already_drawn_per_cell.get(cell.grid_pos, 0)
		num_already_drawn_per_cell[cell.grid_pos] = offset_idx + 1

		var text: String = Enum.to_str(Job.Type, job.type) + " - " + Enum.to_str(Job.Status, job.status)
		var pos := draw_world_pos + _debug_get_offset(offset_idx)
		draw_string(debug_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, debug_font_size, color_actual)


func _debug_get_offset(idx: int) -> Vector2:
	return debug_offset_start + debug_offset_inc * idx


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toogle_jobs_draw"):
		debug_show = not debug_show
		queue_redraw()
