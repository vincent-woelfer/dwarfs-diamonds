class_name Job
extends RefCounted

enum Type {
	MINE,
	BUILD,
	CARRY,
}

enum Status {
	BLOCKED,
	READY,
	IN_PROCESS,
}


var type: Job.Type
var status: Job.Status

# "Center"-Cell of this job (e.g. the cell to be mined)
var target_cell: Cell

# All cells from which this job can be worked on (e.g. for mining: all free neighbouring cells)
var workable_from_grid_poses: Array[Vector2i] = []

var assigned_dwarfs: Array[Dwarf] = []


func _init(type_: Job.Type, cell_: Cell) -> void:
	assert(cell_ != null)

	self.type = type_
	self.target_cell = cell_

	update_workable_from_cells()
	update_status(true)


func assign_dwarf(dwarf: Dwarf) -> void:
	assert(dwarf != null)

	# Job must be READY or IN_PROCESS with assigned dwarfs
	assert(status == Job.Status.READY or (status == Job.Status.IN_PROCESS and !assigned_dwarfs.is_empty()))
	
	status = Job.Status.IN_PROCESS
	Util.array_append_unique_not_null(assigned_dwarfs, dwarf)


func unassign_dwarf(dwarf: Dwarf) -> void:
	assert(dwarf != null)
	assert(status == Job.Status.IN_PROCESS)

	assigned_dwarfs.erase(dwarf)

	if assigned_dwarfs.is_empty():
		# Set back to READY or BLOCKED depending on workable cells
		update_workable_from_cells()
		update_status(true)


func delete() -> void:
	for dwarf in assigned_dwarfs:
		dwarf.job_with_path = null
		dwarf._transition_to_state(Dwarf.Status.IDLE)


func update_workable_from_cells() -> void:
	workable_from_grid_poses = []

	# MINING
	if type == Job.Type.MINE:
		for n_offset: Vector2i in Util.neighbours_cardinal:
			var n_cell: Cell = target_cell.get_neighbour(n_offset)

			# Requires neighbouring target_cell to be free and standable
			if n_cell == null or n_cell.is_solid:
				continue
			
			if n_cell.is_standable():
				workable_from_grid_poses.append(n_cell.grid_pos)


# TODO maybe change to two bools: blocked/ready and in_process/unassigned
func update_status(force_update: bool = false) -> void:
	# Only update if not in progress or forced
	if status != Status.IN_PROCESS or force_update:
		if workable_from_grid_poses.is_empty():
			status = Status.BLOCKED
		else:
			status = Status.READY
