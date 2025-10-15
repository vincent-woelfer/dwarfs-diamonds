class_name JobWithPath
extends RefCounted

var job: Job
var path: Path

func _init(job_: Job, path_: Path) -> void:
    job = job_
    path = path_


# Ensure path is freed when this object is freed.
# Necessary because this struct (RefCounted) has a Node2D as member.
func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        if path and not path.is_queued_for_deletion():
            path.queue_free()
