class_name Dwarf
extends GridObject2D

# Scene Components
@onready var light: PointLight2D = $PointLight2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mining_comp: MiningComponent = $MiningComponent
@onready var building_comp: BuildingComponent = $BuildingComponent
@onready var movement_comp: MovementComponent = $MovementComponent
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Static ID generator
static var next_dwarf_id: int = 0
var dwarf_id: int
var dwarf_color: Color

var job_with_path: JobWithPath

var num_torches: int = 50

# State machine
enum State {IDLE, MOVING, MINING, BUILDING, FALLING, DYING}
var sm: StateMachine
func _physics_process(delta: float) -> void:
	sm.physics_process(delta)

########################################################################################################################
# SETUP & OWN PROCESSING
########################################################################################################################

func setup(grid_pos_: Vector2i, sample_offset_: Vector2 = Global.VERT_OFFSET_SMALL) -> void:
	super.setup(grid_pos_, sample_offset_)

func _ready() -> void:
	sm = StateMachine.new(self, State, State.IDLE)
	sm.set_state_exitable(State.DYING, false)

	# ID + Color
	dwarf_id = next_dwarf_id
	next_dwarf_id += 1
	dwarf_color = Colors.get_rand_dwarf_color(dwarf_id)

	self.z_index = Enum.ZIndex.DWARFS

	# Apply Color
	animated_sprite.modulate = dwarf_color.lerp(Color.WHITE, 0.3)
	light.color = dwarf_color.lerp(light.color, 0.3)

	# Initial Position
	global_position = Global.level.get_cell(grid_pos).get_floor_point()

	# SIGNALS
	EventBus.Signal_NavUpdated.connect(_on_nav_updated)
	EventBus.Signal_DevToogleLight.connect(_dev_toogle_light)

	mining_comp.Signal_OnMiningCompleted.connect(_on_mining_completed)
	
	building_comp.Signal_OnBuildingCompleted.connect(_on_building_completed)

	movement_comp.Signal_MovementDirectionChanged.connect(_on_movement_direction_changed)
	movement_comp.Signal_OnFinishedPath.connect(_on_finished_path)
	movement_comp.Signal_OnStartedFalling.connect(_on_started_falling)
	movement_comp.Signal_OnLanded.connect(_on_landed)
	movement_comp.sm.Signal_StateChanged.connect(_on_movement_state_changed)


########################################################################################################################
# STATE MACHINE HANDLERS
########################################################################################################################

func _physics_process_idle(delta: float) -> void:
	_find_new_job()


func _enter_mining() -> void:
	mining_comp.start_mining(job_with_path.job.center_cell)

	# Look at cell
	var dir_to_cell: Vector2i = (job_with_path.job.center_cell.grid_pos - grid_pos)
	if dir_to_cell.x != 0:
		animated_sprite.flip_h = dir_to_cell.x < 0


func _enter_building(building: BuildingBase) -> void:
	if building == null:
		push_error("%s cannot enter building state with null building, aborting" % [self])
		sm.transition_to(State.IDLE)
		return

	var cell: Cell = Global.level.get_cell(building.grid_pos)
	var cell_from: Cell = self.curr_cell

	if cell == null or cell_from == null:
		push_error("%s cannot enter building state with null cells, aborting" % [self])
		sm.transition_to(State.IDLE)
		return

	building_comp.start_building(cell, cell_from, building)

	# Look at cell
	var dir_to_cell: Vector2i = (job_with_path.job.center_cell.grid_pos - grid_pos)
	if dir_to_cell.x != 0:
		animated_sprite.flip_h = dir_to_cell.x < 0


func _enter_dying() -> void:
	print_rich("%s has died!" % [self])
	
	_abandon_job()

	# Hide player sprite + light
	animated_sprite.visible = false
	light.enabled = false

	# Play death sound
	audio_player.stream = Audio.sounds.get("dwarf_on_landing")
	audio_player.pitch_scale = 1.8
	audio_player.play()


func _physics_process_dying(delta: float) -> void:
	# Wait for sound to finish then free. Dont use await as this is called in physics process
	if not audio_player.playing:
		queue_free()

########################################################################################################################
# SIGNAL HANDLERS
########################################################################################################################
## Triggered by MovementComponent - used for debugging
func _on_movement_state_changed(prev_state: int, next_state: int) -> void:
	pass
	# print_rich("%s MovementComponent state changed from %s to %s" % [self,
		# Enum.to_str(MovementComponent.State, prev_state), Enum.to_str(MovementComponent.State, next_state)])


## Triggered by MovementComponent
func _on_finished_path() -> void:
	job_with_path.path.free()
	job_with_path.path = null

	# TODO handle no job case (should not happen)

	# Validate if we can work on the job
	if not (curr_cell.grid_pos in job_with_path.job.workable_from_poses):
		print_rich("%s reached %s but cannot work from here, abandoning job" % [self, job_with_path.job.center_cell])
		_abandon_job()
		sm.transition_to(State.IDLE)
		return

	# Start working - depends on job type
	if job_with_path.job.job_type == Job.Type.MINE:
		print_rich("%s reached %s and starts mining" % [self, job_with_path.job.center_cell])
		sm.transition_to(State.MINING)
		return
	
	elif job_with_path.job.job_type == Job.Type.RUBBLE:
		print_rich("%s reached %s and starts picking up rubble" % [self, job_with_path.job.center_cell])
		# TODO
		return

	elif job_with_path.job.job_type == Job.Type.BUILD:
		print_rich("%s reached %s and starts building" % [self, job_with_path.job.center_cell])
		# Find building to build - just pick first incomplete one on this cell
		var building_to_build: BuildingBase = null
		for building in job_with_path.job.center_cell.buildings:
			if not building.is_complete:
				building_to_build = building
				break

		if building_to_build != null:
			sm.transition_to(State.BUILDING, building_to_build)
		else:
			print_rich("%s reached %s but found no building to build, abandoning job" % [self, job_with_path.job.center_cell])
			_abandon_job()
			sm.transition_to(State.IDLE)
			
		return

	else:
		print_rich("%s reached %s but job type %s is unhandled, abandoning job" % [self, job_with_path.job.center_cell, Enum.to_str(Job.Type, job_with_path.job.job_type)])
		_abandon_job()
		sm.transition_to(State.IDLE)


## Triggered by MovementComponent
func _on_landed(fall_height_cells: int) -> void:
	if fall_height_cells > 1:
		audio_player.stream = Audio.sounds.get("dwarf_on_landing")
		audio_player.pitch_scale = 1.4
		audio_player.play()

	if fall_height_cells > 5:
		sm.transition_to(State.DYING)
		return

	sm.transition_to(State.IDLE)

	# Simulate entering cell anew with idle (to place torches)
	_on_new_cell_entered(curr_cell)


## Triggered by MovementComponent
func _on_new_cell_entered(new_cell: Cell) -> void:
	_debug_draw_proxy_absolute.queue_redraw()
	
	if new_cell == null:
		return

	# Place Torch but only place if idle or walking
	if sm.state != State.IDLE and sm.state != State.MOVING:
		return

	# Check for torch placement
	if num_torches > 0 and new_cell.deco_elements.is_empty() and Global.level.should_contain_torch(grid_pos):
		print_rich("%s placing torch at %s" % [self, grid_pos])
		num_torches -= 1
		new_cell.add_deco_element()


## Triggered by MovementComponent
func _on_movement_direction_changed(new_dir: Vector2) -> void:
	if new_dir.x != 0:
		animated_sprite.flip_h = new_dir.x < 0


## Triggered by MovementComponent
func _on_started_falling() -> void:
	_abandon_job()
	sm.transition_to(State.FALLING)


## Triggered by MiningComponent
func _on_mining_completed(mined_cell: Cell) -> void:
	print_rich("%s completed mining %s" % [self, job_with_path.job])

	# Complete job
	if job_with_path != null:
		job_with_path.job.complete(self)

		# Clear job reference
		if job_with_path.path != null:
			job_with_path.path.free()

		job_with_path = null

	# Transition back to idle but dont override falling state
	if sm.state != State.FALLING:
		sm.transition_to(State.IDLE)


## Triggered by BuildingComponent
func _on_building_completed(building: BuildingBase) -> void:
	# Dont access job here, is already deleted
	print_rich("%s completed building %s" % [self, building])

	# Complete job
	if job_with_path != null:
		job_with_path.job.complete(self)

		# Clear job reference
		if job_with_path.path != null:
			job_with_path.path.free()

		job_with_path = null

	# Transition back to idle but dont override falling state
	if sm.state != State.FALLING:
		sm.transition_to(State.IDLE)


## Triggered by Job. When job is deleted - not for the dwarf calling job.complete
func on_job_deleted() -> void:
	if job_with_path == null:
		return

	print_rich("%s's job was deleted" % [self])

	_abandon_job()

	# Abort mining
	if sm.state == State.MINING:
		mining_comp.stop_mining_all_cells()

	# Transition back to idle but dont override falling state
	if sm.state != State.FALLING:
		sm.transition_to(State.IDLE)


## Triggered by NavMesh updates (via EventBus)
func _on_nav_updated() -> void:
	# If nav updated while following a path -> recalculate path for job or abort if not valid
	if job_with_path != null:
		_validate_current_path()


########################################################################################################################
# OWN (UTILITY) FUNCTIONS
########################################################################################################################
func _abandon_job() -> void:
	if job_with_path == null:
		return

	print_rich("%s abandoning %s" % [self, job_with_path.job])
	if job_with_path.path != null:
		if movement_comp.sm.state == MovementComponent.State.FOLLOWING_PATH:
			movement_comp.abort_path()
		job_with_path.path.free()
	if job_with_path.job != null:
		job_with_path.job.unassign_dwarf(self)
	job_with_path = null


func _find_new_job() -> void:
	# Try to get a new job	
	var new_job_with_path: JobWithPath = Global.level.job_manager.get_new_job_for_worker(self)

	if new_job_with_path == null:
		HexLog.print_throttled(self, "%s found no job, remains idle" % [self], 0.5)
		return

	var success: bool = false
	if movement_comp.assign_path(new_job_with_path.path):
		if new_job_with_path.job.assign_dwarf(self):
			success = true
			job_with_path = new_job_with_path
			job_with_path.path.set_debug_draw_color(dwarf_color)
		
			sm.transition_to(State.MOVING)
			print_rich("%s started %s" % [self, job_with_path.job])

	if not success:
		# Cleanup on failure
		movement_comp.abort_path()
		print_rich("%s failed to assign job/path to %s, remaining idle" % [self, new_job_with_path.job])


func _validate_current_path() -> void:
	if not job_with_path or not job_with_path.path:
		return

	job_with_path.path.free()
	job_with_path.path = null
	
	# Force job to update workable cells first
	job_with_path.job.update_workable_from_cells()
	var new_path: Path = Global.level.nav_manager.find_path_to_one_of(grid_pos, job_with_path.job.workable_from_poses)

	if new_path != null:
		if movement_comp.assign_path(new_path):
			job_with_path.path = new_path
			job_with_path.path.set_debug_draw_color(dwarf_color)
		
	else:
		print_rich("%s lost path to job at %s" % [self, job_with_path.job.center_cell])
		job_with_path.job.unassign_dwarf(self)
		movement_comp.abort_path()
		job_with_path = null
		sm.transition_to(State.IDLE)


func _to_string() -> String:
	var print_color := Colors.to_print_color(dwarf_color)
	return Util.color_string("Dwarf-%d (%s @ %s)" % [dwarf_id, Enum.to_str(State, sm.state), grid_pos], print_color)

########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy := DebugDrawProxy.new(self)
var _debug_draw_proxy_absolute := DebugDrawProxy.new(self, false)

const debug_state_colors := {
	State.IDLE: Color.WHITE, # White
	State.MOVING: Color(1.0, 1.0, 0.0), # Yellow
	State.MINING: Color(1.0, 0.0, 0.0), # Red
	State.BUILDING: Color(0.0, 1.0, 0.0), # GREEN
	State.FALLING: Color(1.0, 0.0, 1.0), # Magenta
	State.DYING: Color(0.0, 0.0, 0.0), # Black
}

const debug_label_width := 0.9 * Global.CELL_SIZE
const debug_label_offset := Vector2(0.0, -0.8) * Global.CELL_SIZE_VEC + Vector2(-debug_label_width / 2.0, 0.0)
const debug_occupied_cell_alpha := 0.1

var debug_font := ThemeDB.fallback_font
var debug_font_size := 22


func _debug_draw_in_ui(ui_layer: CanvasItem) -> void:
	# Status Text
	var color_actual: Color = debug_state_colors.get(sm.state, Colors.FALLBACK_COLOR)
	var text: String = Enum.to_str(Dwarf.State, sm.state)
	ui_layer.draw_string(debug_font, debug_label_offset, text, HORIZONTAL_ALIGNMENT_CENTER, debug_label_width, debug_font_size, color_actual)


func _debug_draw_in_ui_absolute(ui_layer: CanvasItem) -> void:
	# Draw Occupied Cell
	var cell_to_draw: Cell = curr_cell

	if cell_to_draw != null:
		var offset: Vector2 = cell_to_draw.global_position
		var cell_poly_points := cell_to_draw.visual.poly_points.duplicate()
		for i in range(cell_poly_points.size()):
			cell_poly_points[i] += offset

		ui_layer.draw_colored_polygon(cell_poly_points, Colors.with_alpha(dwarf_color, debug_occupied_cell_alpha))


func _dev_toogle_light(is_light_on: bool) -> void:
	light.enabled = is_light_on
