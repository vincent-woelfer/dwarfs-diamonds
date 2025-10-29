class_name Dwarf
extends GridObject2D

# Scene Components
@onready var light: PointLight2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mining_comp: MiningComponent = $MiningComponent
@onready var falling_comp: FallingComponent = $FallingComponent
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

static var next_dwarf_id: int = 0
var dwarf_id: int
var speed := 250.0 # pixels per second

enum Status {IDLE, MOVING, MINING, FALLING}
var _status: Status

var job_with_path: JobWithPath

var num_torches: int = 50


func _init(grid_pos_: Vector2i) -> void:
	super (grid_pos_)


func _ready() -> void:
	dwarf_id = next_dwarf_id
	next_dwarf_id += 1

	_status = Status.IDLE
	global_position = Global.level.get_cell(grid_pos).get_floor_point()

	EventBus.Signal_NavUpdated.connect(_on_nav_updated)
	mining_comp.Signal_OnMiningCompleted.connect(_on_mining_completed)

	EventBus.Signal_DevToogleLight.connect(_dev_toogle_light)


# TODO implement state machine properly
func _physics_process(delta: float) -> void:
	# Update grid cell before anything else
	_sample_grid_pos()

	if _status == Status.IDLE:
		_tick_idle(delta)
	elif _status == Status.MOVING:
		_tick_moving(delta)
	elif _status == Status.MINING:
		_tick_mining(delta)
	elif _status == Status.FALLING:
		# Do nothing, falling component handles everything
		pass
		
func _transition_to_state(new_status: Status) -> void:
	_status = new_status
	_debug_draw_proxy.queue_redraw()
	

func _tick_idle(delta: float) -> void:
	# Try to get a new job
	var new_job_with_path: JobWithPath = Global.level.job_manager.get_new_job_for_worker(grid_pos)

	if new_job_with_path != null:
		job_with_path = new_job_with_path

		job_with_path.job.assign_dwarf(self)
		job_with_path.path.update_following_index_to_closest(global_position)
		job_with_path.path.debug_draw = true
		
		print("%s started job %s at %s" % [self, Enum.to_str(Job.Type, job_with_path.job.type), job_with_path.job.target_cell])

		_transition_to_state(Status.MOVING)
	else:
		# TODO HANGS HERE WHEN due to climbing current grid_cell is the diagonal one which is not a nav cell -> no possible job found
		print("%s found no job, remains idle" % [self])
		pass


func _tick_moving(delta: float) -> void:
	# Follow path
	var new_pos: Vector2 = job_with_path.path.follow_path(global_position, speed * delta)
	var move_vector: Vector2 = new_pos - global_position
	global_position = new_pos

	# TODO remove, dont sample while moving, get cell from path
	_sample_grid_pos()

	# Turn sprite
	if move_vector.x != 0.0:
		animated_sprite.flip_h = move_vector.x < 0.0

	# Reached job
	if job_with_path.path.reached_end():
		job_with_path.path.free()
		job_with_path.path = null

		# Start working - depends on job type
		# TODO other job types
		print("%s reached %s and starts mining" % [self, job_with_path.job.target_cell])

		_transition_to_state(Status.MINING)
		mining_comp.start_mining(job_with_path.job.target_cell)


func _on_enter_new_grid_pos() -> void:
	var new_cell: Cell = Global.level.get_cell(grid_pos)
	if new_cell == null:
		return

	# Place Torch
	# -> Only place if idle or walking
	if _status != Status.IDLE and _status != Status.MOVING:
		return

	# Check for torch placement
	if num_torches > 0 and new_cell.deco_elements.is_empty() and Global.level.should_contain_torch(grid_pos):
		print("%s placing torch at %s" % [self, grid_pos])
		num_torches -= 1
		new_cell.add_deco_element()


func _tick_mining(delta: float) -> void:
	# Mining is handled in MiningComponent
	pass


func _on_mining_completed(mined_cell: Cell) -> void:
	print("%s completed mining job at %s" % [self, mined_cell.grid_pos])

	# Complete job
	if job_with_path != null:
		job_with_path.job.complete(self)

		# Clear job reference
		if job_with_path.path != null:
			job_with_path.path.free()

		job_with_path = null

	# Transition back to idle but dont override falling state
	if _status != Status.FALLING:
		_transition_to_state(Status.IDLE)


func _on_started_falling() -> void:
	if job_with_path != null:
		# Abandon job
		if job_with_path.path != null:
			job_with_path.path.free()
		job_with_path.job.unassign_dwarf(self)
		job_with_path = null

	_transition_to_state(Status.FALLING)


func _on_landed(fall_height_cells: int) -> void:
	if fall_height_cells > 1:
		audio_player.stream = Audio.sounds.get("dwarf_on_landing")
		audio_player.play()

	_transition_to_state(Status.IDLE)

	# Simulate entering cell anew with idle (to place torches)
	_on_enter_new_grid_pos()


## Called externally when job is deleted - not for the dwarf calling job.complete
func on_job_deleted() -> void:
	if job_with_path == null:
		return

	print("%s's job was deleted" % [self])

	# Delete own reference
	if job_with_path.path != null:
		job_with_path.path.free()
	job_with_path = null

	# Transition back to idle but dont override falling state
	if _status != Status.FALLING:
		_transition_to_state(Status.IDLE)


func _on_nav_updated() -> void:
	# If nav updated while moving -> recalculate path for job or abort if not valid
	if job_with_path and job_with_path.path != null:
		job_with_path.path.free()
		job_with_path.path = null
		
		# Force job to update workable cells first
		job_with_path.job.update_workable_from_cells()
		var new_path: Path = Global.level.nav.find_path_to_one_of(grid_pos, job_with_path.job.workable_from_grid_poses)

		if new_path != null:
			job_with_path.path = new_path
			job_with_path.path.update_following_index_to_closest(global_position)
			job_with_path.path.debug_draw = true
		else:
			print("%s lost path to job at %s" % [self, job_with_path.job.target_cell])
			job_with_path.job.unassign_dwarf(self)
			job_with_path = null
			_transition_to_state(Status.IDLE)


func _to_string() -> String:
	return "Dwarf(id=%d, pos=%s, status=%s)" % [dwarf_id, grid_pos, Enum.to_str(Status, _status)]


########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy := DebugDrawProxy.new(self)

const debug_status_colors := {
	Status.IDLE: Color.WHITE,
	Status.MOVING: Color(1.0, 1.0, 0.0),
	Status.MINING: Color(1.0, 0.0, 0.0),
	Status.FALLING: Color(1.0, 0.0, 1.0),
}

const debug_label_width := 0.9 * Global.CELL_SIZE
const debug_offset := Vector2(0.0, -0.8) * Global.CELL_SIZE_VEC + Vector2(-debug_label_width / 2.0, 0.0)

var debug_font := ThemeDB.fallback_font
var debug_font_size := 22


func _debug_draw_in_ui(ui_layer: CanvasItem) -> void:
	var color_actual: Color = debug_status_colors.get(_status, Colors.DEFAULT)
	var text: String = Enum.to_str(Dwarf.Status, _status)
	ui_layer.draw_string(debug_font, debug_offset, text, HORIZONTAL_ALIGNMENT_CENTER, debug_label_width, debug_font_size, color_actual)


func _dev_toogle_light(is_light_on: bool) -> void:
	light.enabled = is_light_on
