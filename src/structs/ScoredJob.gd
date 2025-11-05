class_name ScoredJob
extends RefCounted

var job: Job = null
var path: Path = null
var score: float = 0.0

func _init(job_: Job, path_: Path, score_: float) -> void:
    job = job_
    path = path_
    score = score_

# Comparison function for sorting - lower score is better
static func compare(a: ScoredJob, b: ScoredJob) -> bool:
    return a.score < b.score
