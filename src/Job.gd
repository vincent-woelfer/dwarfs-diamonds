class_name Job
extends RefCounted

###################################
# ENUM DEFINITIONS
###################################
enum Type {
	MINE,
	BUILD,
	PICKUP,
}

###################################
# SHARED VARIABLES
###################################
var job_type: Job.Type

# "Center"-Cell of this job (e.g. the cell to be mined, or the cell containing the rubble)
var center_cell: Cell

# All cells from which this job can be worked on (e.g. for mining: all free neighbouring cells)
var workable_from_poses: Array[Vector2i] = []

# Currently assigned dwarfs
var assigned_dwarfs: Array[Dwarf] = []

# Associated action point (if any)
var action_point: ActionPoint = null

# Only active jobs are listed in job-manager.
# Non-active means completed or aborted and are only used for dwarfs to reference them in their finished-job callback.
var is_active: bool

# Only meaningful after job was archived ( is_active=false )
var success: bool


###################################
# For MINE jobs
###################################


###################################
# For PICKUP jobs
###################################
var carryable_item: Item = null

###################################
# For BUILD jobs
###################################
var building: BuildingBase = null


########################################################################################################################
# PUBLIC METHODS
########################################################################################################################

## Generates the list of tasks required to complete this job.
func generate_tasks() -> Array[Task]:
	var tasks: Array[Task] = []

	match job_type:
		Job.Type.MINE:
			tasks.append(Task.create_move_to_job_task(self ))
			tasks.append(Task.create_mine_task(center_cell.grid_pos))

		Job.Type.BUILD:
			tasks.append(Task.create_move_to_job_task(self ))
			tasks.append(Task.create_construct_task(center_cell.grid_pos, building))

		Job.Type.PICKUP:
			tasks.append(Task.create_move_to_job_task(self ))
			tasks.append(Task.create_pickup_task(center_cell.grid_pos, carryable_item))
	return tasks


########################################################################################################################
func calculate_capacity() -> int:
	match job_type:
		Job.Type.MINE:
			# Up to 2 dwarfs can mine simultaneously (if enough space)
			return min(2, workable_from_poses.size())

		Job.Type.BUILD:
			# Only allow multiple dwarfs for big buildings
			const big_building_build_time_threshold := 3.0 # seconds
			if building.building_data.build_time >= big_building_build_time_threshold and building.build_process == 0.0 and workable_from_poses.size() >= 2:
				return 2
			return 1

		Job.Type.PICKUP:
			return 1

	assert(false)
	return 0


## Basic checks whether this job is blocked or ready
func is_workable() -> bool:
	if assigned_dwarfs.size() >= calculate_capacity():
		return false
	if workable_from_poses.is_empty():
		return false

	return true


func assign_dwarf(dwarf: Dwarf) -> bool:
	assert(dwarf != null)

	if dwarf in assigned_dwarfs:
		return false
	if assigned_dwarfs.size() >= calculate_capacity():
		return false

	Util.array_append_unique_not_null(assigned_dwarfs, dwarf)

	return true


func unassign_dwarf(dwarf: Dwarf) -> void:
	assert(dwarf != null)
	assert(assigned_dwarfs.has(dwarf))
	assigned_dwarfs.erase(dwarf)


## Signals all working dwarfs (also the one finishing this job) that the job is finished.
## ONLY CALL VIA GLOBAL ACTIONS.
func archive_internal(success_: bool) -> void:
	# Ensure this is only triggered once
	if not is_active:
		push_error("Trying to archive job %s but was archived before (is_active=false)" % [ self ])
		return

	is_active = false
	success = success_

	for dwarf in assigned_dwarfs:
		dwarf._on_job_archived()


func update_workable_from_cells() -> void:
	var can_use_ladders: bool = true
	workable_from_poses.clear()

	# MINING / BUILD PLATFORM
	if job_type == Job.Type.MINE:
		for n_offset: Vector2i in Util.neighbours_cardinal:
			var n_cell: Cell = center_cell.get_neighbour(n_offset)

			if !n_cell or not n_cell.is_standable(can_use_ladders):
				continue

			workable_from_poses.append(n_cell.grid_pos)

	# BUILD
	elif job_type == Job.Type.BUILD:
		for n_grid_pos: Vector2i in building.building_data.pattern_build_from.get_world_positions():
			var n_cell: Cell = Global.level.get_cell(n_grid_pos)

			if !n_cell or not n_cell.is_standable(can_use_ladders):
				continue
			
			workable_from_poses.append(n_cell.grid_pos)

		# For ladders, only allow building from outside center cell if it isnt possible from there.
		if building.building_data.type == BuildingDataRes.Type.LADDER:
			if building.grid_pos in workable_from_poses:
				workable_from_poses.clear()
				workable_from_poses.append(building.grid_pos)

	# PICKUP
	elif job_type == Job.Type.PICKUP:
		if carryable_item.can_be_picked_up_right_now():
			workable_from_poses.append(center_cell.grid_pos)


## Estimates remaining time in seconds. For now only works when dwarf already arrived at job.
## Used for other dwarfs to decide whether to take this job or not.
const MAX_REMAINING_TIME_ESTIMATE: float = 60.0 * 5.0 # 5 minutes
func estimate_remaining_time() -> float:
	if assigned_dwarfs.is_empty():
		return MAX_REMAINING_TIME_ESTIMATE

	# Simple estimate based on job type
	var remaining_time: float = MAX_REMAINING_TIME_ESTIMATE

	match job_type:
		Job.Type.MINE:
			for dwarf in assigned_dwarfs:
				# If at least one dwarf is already mining -> use its speed
				if dwarf.sm.state == Dwarf.State.MINING:
					var remaining_process: float = 1.0 - center_cell.mining_process
					var time := remaining_process / dwarf.mining_comp.mining_speed
					remaining_time = min(remaining_time, time)

				# Dwarf still walking to job
				else:
					if dwarf.curr_path:
						# Estimate time based on path length and walking speed
						var time := dwarf.curr_path.get_remaining_time(dwarf.movement_comp.movement_stats)
						remaining_time = min(remaining_time, time + 5.0) # +5s buffer for starting mining

			return remaining_time

		Job.Type.BUILD:
			for dwarf in assigned_dwarfs:
				# If at least one dwarf is already building -> use its speed
				if dwarf.sm.state == Dwarf.State.BUILDING:
					var remaining_process: float = 1.0 - building.build_process
					var time := remaining_process / dwarf.construction_comp.building_speed
					remaining_time = min(remaining_time, time)

				# Dwarf still walking to job
				else:
					if dwarf.curr_path:
						# Estimate time based on path length and walking speed
						var time := dwarf.curr_path.get_remaining_time(dwarf.movement_comp.movement_stats)
						remaining_time = min(remaining_time, time + 5.0) # +5s buffer for starting building
						
			return 0.0

		Job.Type.PICKUP:
			# Only one dwarf can do this job
			return 0.0


	# Other job types not implemented yet
	assert(false)
	return MAX_REMAINING_TIME_ESTIMATE


########################################################################################################################
# INTERNAL METHODS
########################################################################################################################
func _init(type_: Job.Type, cell_: Cell) -> void:
	assert(cell_ != null)
	is_active = true

	self.job_type = type_
	self.center_cell = cell_
	self.assigned_dwarfs = []


########################################################################################################################
# DEBUG
########################################################################################################################
## info[0] = job type string (MINE, BUILD, etc)
## info[1] = status string (BLOCKED, READY, DOING (x/y), ARCHIVED)
## info[2] = status color
func get_debug_info() -> Array:
	var info: Array[Variant] = []
	info.resize(3)

	# Job Type - default. Overridden for some types below
	info[0] = Enum.to_str(Job.Type, job_type)

	if not is_active:
		info[1] = "ARCHIVED"
		info[2] = Colors.JOB_COLOR_ARCHIVED
		return info

	# "Status"
	if workable_from_poses.is_empty():
		info[1] = "BLOCKED"
		info[2] = Colors.JOB_COLOR_BLOCKED
	else:
		if assigned_dwarfs.is_empty():
			info[1] = "READY"
			info[2] = Colors.JOB_COLOR_READY
		else:
			info[1] = "DOING %d/%d" % [assigned_dwarfs.size(), calculate_capacity()]
			info[2] = Colors.JOB_COLOR_DOING

	# Override/modify with additional info
	if job_type == Job.Type.PICKUP:
		if carryable_item.item_type == Item.ItemType.RUBBLE:
			info[0] += "-RUB"
			@warning_ignore("unsafe_method_access")
			info[2] = info[2].darkened(0.5)
		elif carryable_item.item_type == Item.ItemType.GEMSTONE:
			info[0] += "-GEM"
			@warning_ignore("unsafe_method_access")
			info[2] = info[2].lerp(Color.CYAN, 0.4)

	return info


func _to_string() -> String:
	var info := get_debug_info()
	var color: Color = info[2]
	color = Colors.to_print_color(color)
	return Util.color_string("Job(%s - %s @%s)" % [info[0], info[1], center_cell.grid_pos], color)
