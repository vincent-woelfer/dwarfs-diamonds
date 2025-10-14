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

var cell: Cell

var workable_from_cells: Array[Cell] = []


func _init(type_: Job.Type, cell_: Cell) -> void:
	assert(cell_ != null)

	self.type = type_
	self.cell = cell_

	self.status = Job.Status.BLOCKED
	
	update_workable_from_cells()


func update_workable_from_cells() -> void:
	if type == Job.Type.MINE:
		workable_from_cells = []
		for n_offset: Vector2i in Util.neighbours_cardinal:
			var n_cell := cell.get_neighbour(n_offset)

			# Requires neighbouring cell to be free and standable
			if n_cell == null or n_cell.is_solid:
				continue
			
			if n_cell.is_standable():
				workable_from_cells.append(n_cell)
	
	# Update Status
	if status != Status.IN_PROCESS:
		if workable_from_cells.size() == 0:
			status = Status.BLOCKED
		else:
			status = Status.READY

	# else:
	# 	workable_from_cells = []
