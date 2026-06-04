class_name JobWithPath
extends RefCounted

var job: AbstractJob = null
var path: Path = null


func _init(job_: AbstractJob, path_: Path) -> void:
	job = job_
	path = path_
