class_name ScoredJob
extends RefCounted

var job: Job = null
var path: Path = null

## Lower score is better. Estimates how efficient this dward can complete the job
var score: float = 0.0

## For gather tasks
var items_to_gather: ItemTypeList = null

func _init(job_: Job, path_: Path, score_: float, _items_to_gather: ItemTypeList = null) -> void:
    job = job_
    path = path_
    score = score_
    items_to_gather = _items_to_gather

# Comparison function for sorting - lower score is better
static func compare(a: ScoredJob, b: ScoredJob) -> bool:
    return a.score < b.score
