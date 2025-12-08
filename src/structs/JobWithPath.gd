class_name JobWithPath
extends RefCounted

var job: Job = null
var path: Path = null

func _init(job_: Job, path_: Path) -> void:
    job = job_
    path = path_
