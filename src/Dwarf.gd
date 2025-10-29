class_name Dwarf
extends GridObject2D

# Scene Components
@onready var light: PointLight2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mining_comp: MiningComponent = $MiningComponent
@onready var movement_comp: MovementComponent = $MovementComponent
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

static var next_dwarf_id: int = 0
var dwarf_id: int

enum State {IDLE, MOVING, MINING, FALLING}
var _state: State

var job_with_path: JobWithPath

var num_torches: int = 50

func setup(grid_pos_: Vector2i, sample_offset_: Vector2 = Global.VERT_OFFSET_SMALL) -> void:
	super.setup(grid_pos_, sample_offset_)

func _ready() -> void:
	dwarf_id = next_dwarf_id
	next_dwarf_id += 1

	_state = State.IDLE
	global_position = Global.level.get_cell(grid_pos).get_floor_point()

	# SIGNALS
	EventBus.Signal_NavUpdated.connect(_on_nav_updated)
	EventBus.Signal_DevToogleLight.connect(_dev_toogle_light)

	mining_comp.Signal_OnMiningCompleted.connect(_on_mining_completed)

	movement_comp.Signal_MovementDirectionChanged.connect(_on_movement_direction_changed)
	movement_comp.Signal_OnFinishedPath.connect(_on_finished_path)
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)


# TODO implement state machine properly
func _physics_process(delta: float) -> void:
	if _state == State.IDLE:
		_tick_idle(delta)
	elif _state == State.MOVING:
		pass
	elif _state == State.MINING:
		_tick_mining(delta)
	elif _state == State.FALLING:
		pass


func _transition_to_state(new_state: State) -> void:
	_state = new_state
	_debug_draw_proxy.queue_redraw()
	

func _tick_idle(delta: float) -> void:
	# Try to get a new job
	var new_job_with_path: JobWithPath = Global.level.job_manager.get_new_job_for_worker(grid_pos)

	if new_job_with_path != null:
		job_with_path = new_job_with_path

		job_with_path.job.assign_dwarf(self)
		movement_comp.assign_path(job_with_path.path)
		_transition_to_state(State.MOVING)

		print("%s started job %s at %s" % [self, Enum.to_str(Job.Type, job_with_path.job.type), job_with_path.job.target_cell])

	else:
		# TODO HANGS HERE WHEN due to climbing current grid_cell is the diagonal one which is not a nav cell -> no possible job found
		# print("%s found no job, remains idle" % [self])
		pass


func _on_finished_path() -> void:
	job_with_path.path.free()
	job_with_path.path = null

	# Start working - depends on job type
	# TODO other job types
	print("%s reached %s and starts mining" % [self, job_with_path.job.target_cell])

	_transition_to_state(State.MINING)
	mining_comp.start_mining(job_with_path.job.target_cell)


func _on_new_cell_entered(new_cell: Cell) -> void:
	if new_cell == null:
		return

	# Place Torch
	# -> Only place if idle or walking
	if _state != State.IDLE and _state != State.MOVING:
		return

	# Check for torch placement
	if num_torches > 0 and new_cell.deco_elements.is_empty() and Global.level.should_contain_torch(grid_pos):
		print("%s placing torch at %s" % [self, grid_pos])
		num_torches -= 1
		new_cell.add_deco_element()


func _tick_mining(delta: float) -> void:
	# Mining is handled in MiningComponent
	pass


func _on_movement_direction_changed(new_dir: Vector2) -> void:
	if new_dir.x != 0:
		animated_sprite.flip_h = new_dir.x < 0


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
	if _state != State.FALLING:
		_transition_to_state(State.IDLE)


func _on_started_falling() -> void:
	if job_with_path != null:
		# Abandon job
		if job_with_path.path != null:
			job_with_path.path.free()
		job_with_path.job.unassign_dwarf(self)
		job_with_path = null

	_transition_to_state(State.FALLING)


func _on_landed(fall_height_cells: int) -> void:
	if fall_height_cells > 1:
		audio_player.stream = Audio.sounds.get("dwarf_on_landing")
		audio_player.play()

	_transition_to_state(State.IDLE)

	# Simulate entering cell anew with idle (to place torches)
	_on_new_cell_entered(curr_cell)


## Called externally when job is deleted - not for the dwarf calling job.complete
func on_job_deleted() -> void:
	if job_with_path == null:
		return

	print("%s's job was deleted" % [self])

	# Delete own reference
	if job_with_path.path != null:
		movement_comp.abort_path()
		job_with_path.path.free()
	job_with_path = null

	# Transition back to idle but dont override falling state
	if _state != State.FALLING:
		_transition_to_state(State.IDLE)


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
			movement_comp.assign_path(job_with_path.path)
		else:
			print("%s lost path to job at %s" % [self, job_with_path.job.target_cell])
			job_with_path.job.unassign_dwarf(self)
			movement_comp.abort_path()
			job_with_path = null
			_transition_to_state(State.IDLE)


func _to_string() -> String:
	return "Dwarf(id=%d, pos=%s, state=%s)" % [dwarf_id, grid_pos, Enum.to_str(State, _state)]


########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy := DebugDrawProxy.new(self)

const debug_state_colors := {
	State.IDLE: Color.WHITE,
	State.MOVING: Color(1.0, 1.0, 0.0),
	State.MINING: Color(1.0, 0.0, 0.0),
	State.FALLING: Color(1.0, 0.0, 1.0),
}

const debug_label_width := 0.9 * Global.CELL_SIZE
const debug_offset := Vector2(0.0, -0.8) * Global.CELL_SIZE_VEC + Vector2(-debug_label_width / 2.0, 0.0)

var debug_font := ThemeDB.fallback_font
var debug_font_size := 22


func _debug_draw_in_ui(ui_layer: CanvasItem) -> void:
	var color_actual: Color = debug_state_colors.get(_state, Colors.DEFAULT)
	var text: String = Enum.to_str(Dwarf.State, _state)
	ui_layer.draw_string(debug_font, debug_offset, text, HORIZONTAL_ALIGNMENT_CENTER, debug_label_width, debug_font_size, color_actual)


func _dev_toogle_light(is_light_on: bool) -> void:
	light.enabled = is_light_on
