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


func _init(type_: Job.Type, status_: Job.Status, cell_: Cell) -> void:
	assert(cell_ != null)
	
	self.type = type_
	self.status = status_
	self.cell = cell_
