class_name Job
extends RefCounted

var type: Enum.JobType
var status: Enum.JobStatus

var start_cell: Cell

func _init(type_: Enum.JobType, status_: Enum.JobStatus, start_cell_: Cell) -> void:
	self.type = type_
	self.status = status_
	self.start_cell = start_cell_
