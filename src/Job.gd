class_name Job
extends RefCounted

########################################################################################################################
# ENUM DEFINITIONS
########################################################################################################################
enum Type {
	MINE,
	BUILD,
	RUBBLE,
}

var job_type: Job.Type

# "Center"-Cell of this job (e.g. the cell to be mined)
var center_cell: Cell

# All cells from which this job can be worked on (e.g. for mining: all free neighbouring cells)
var workable_from_poses: Array[Vector2i] = []

# Currently assigned dwarfs
var assigned_dwarfs: Array[Dwarf] = []


###################################
# For RUBBLE jobs
###################################
var rubble: Rubble = null

###################################
# For BUILD jobs
###################################
var building: BuildingBase = null


########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func get_capacity() -> int:
	if job_type == Job.Type.MINE:
		return 2
	elif job_type == Job.Type.BUILD:
		# Only work on big buildings with multiple dwarfs
		if building != null and building.building_data.build_time > 5.0 and building.build_process == 0.0 and workable_from_poses.size() >= 2:
			return 2
		return 1
	elif job_type == Job.Type.RUBBLE:
		return 1

	assert(false)
	return 0


func is_workable() -> bool:
	if assigned_dwarfs.size() >= get_capacity():
		return false

	if workable_from_poses.is_empty():
		return false

	return true


func assign_dwarf(dwarf: Dwarf) -> bool:
	assert(dwarf != null)

	if dwarf in assigned_dwarfs:
		return false

	if assigned_dwarfs.size() >= get_capacity():
		return false

	Util.array_append_unique_not_null(assigned_dwarfs, dwarf)

	return true


func unassign_dwarf(dwarf: Dwarf) -> void:
	assert(dwarf != null)
	assert(assigned_dwarfs.has(dwarf))

	assigned_dwarfs.erase(dwarf)


## Dont use for finishing jobs
func delete() -> void:
	for dwarf in assigned_dwarfs:
		dwarf.on_job_deleted()
	assigned_dwarfs.clear()


func complete(dwarf: Dwarf) -> void:
	if dwarf != null:
		unassign_dwarf(dwarf)

	# Delete for other dwarfs TODO should we not call finish for them?
	# TODO FIX THIS
	delete()


func update_workable_from_cells() -> void:
	workable_from_poses.clear()

	# MINING
	if job_type == Job.Type.MINE:
		for n_offset: Vector2i in Util.neighbours_cardinal:
			var n_cell: Cell = center_cell.get_neighbour(n_offset)

			if n_cell == null:
				continue
			
			if n_cell.is_standable(false):
				workable_from_poses.append(n_cell.grid_pos)

	# BUILD
	elif job_type == Job.Type.BUILD:
		for n_grid_pos: Vector2i in building.building_data.pattern_build_from.get_world_positions():
			var n_cell: Cell = Global.level.get_cell(n_grid_pos)

			if n_cell == null:
				continue
			
			if n_cell.is_standable(false):
				workable_from_poses.append(n_cell.grid_pos)

	# RUBBLE
	elif job_type == Job.Type.RUBBLE:
		# Can only pick up rubble when not falling
		if rubble.can_pickup():
			workable_from_poses.append(center_cell.grid_pos)
		

## Estimates remaining time in seconds. For now only works when dwarf already arrived at job.
## Used for other dwarfs to decide whether to take this job or not.
const MAX_REMAINING_TIME_ESTIMATE: float = 1000.0
func estimate_remaining_time() -> float:
	if assigned_dwarfs.is_empty():
		return MAX_REMAINING_TIME_ESTIMATE

	# Simple estimate based on job type
	if job_type == Job.Type.MINE:
		var remaining_time: float = MAX_REMAINING_TIME_ESTIMATE

		for dwarf in assigned_dwarfs:
			# If at least one dwarf is already mining -> use its speed
			if dwarf.sm.state == Dwarf.State.MINING:
				var remaining_process: float = 1.0 - center_cell.mining_process
				var time := remaining_process / dwarf.mining_comp.mining_speed
				remaining_time = min(remaining_time, time)

			# Dwarf still walking to job
			else:
				if dwarf.job_with_path and dwarf.job_with_path.path:
					# Estimate time based on path length and walking speed
					var path_length: float = dwarf.job_with_path.path.get_remaining_length_world_space()
					var walking_speed := dwarf.movement_comp.movement_capabilities.get_speed(Enum.MoveMode.WALK)
					var time := path_length / walking_speed
					remaining_time = min(remaining_time, time + 5.0) # +5s buffer for starting mining

		return remaining_time

	elif job_type == Job.Type.BUILD:
		var remaining_time: float = MAX_REMAINING_TIME_ESTIMATE
		for dwarf in assigned_dwarfs:
			# If at least one dwarf is already building -> use its speed
			if dwarf.sm.state == Dwarf.State.BUILDING:
				var remaining_process: float = 1.0 - building.build_process
				var time := remaining_process / dwarf.building_comp.building_speed
				remaining_time = min(remaining_time, time)

			# Dwarf still walking to job
			else:
				if dwarf.job_with_path and dwarf.job_with_path.path:
					# Estimate time based on path length and walking speed
					var path_length: float = dwarf.job_with_path.path.get_remaining_length_world_space()
					var walking_speed := dwarf.movement_comp.movement_capabilities.get_speed(Enum.MoveMode.WALK)
					var time := path_length / walking_speed
					remaining_time = min(remaining_time, time + 5.0) # +5s buffer for starting building
		return 0.0

	elif job_type == Job.Type.RUBBLE:
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

	self.job_type = type_
	self.center_cell = cell_
	self.assigned_dwarfs = []


########################################################################################################################
# DEBUG
########################################################################################################################
## info[0] = job type string
## info[1] = status string
## info[2] = status color
func get_debug_info() -> Array:
	var info: Array
	info.resize(3)

	# Job Type
	info[0] = Enum.to_str(Job.Type, job_type)

	# "Status"
	if workable_from_poses.is_empty():
		info[1] = "BLOCKED"
		info[2] = Color.RED
	else:
		if assigned_dwarfs.is_empty():
			info[1] = "READY"
			info[2] = Color.BLUE
		else:
			info[1] = "DOING (%d/%d)" % [assigned_dwarfs.size(), get_capacity()]
			info[2] = Color.GREEN

	return info


func _to_string() -> String:
	var info := get_debug_info()
	var color: Color = info[2]
	color = Colors.to_print_color(color)
	return Util.color_string("Job(%s - %s @ %s)" % [info[0], info[1], center_cell.grid_pos], color)
