class_name DwarfJobsAssignment
extends RefCounted

var dwarfs: Array[Dwarf] = []
var jobs: Array[AbstractJob] = []

## Size of jobs not null
var total_assigned_jobs: int = 0

## Size of dwarfs
var total_size: int = 0

func _init(_dwarfs: Array[Dwarf] = [], _jobs: Array[AbstractJob] = []) -> void:
    assert(_dwarfs.size() == _jobs.size())
    dwarfs = _dwarfs
    jobs = _jobs

    # Count jobs not null
    total_assigned_jobs = jobs.reduce(func(counter: int, job: AbstractJob) -> int: return counter + (1 if job != null else 0), 0)
    total_size = dwarfs.size()


func add_assignment(dwarf: Dwarf, job: AbstractJob) -> void:
    dwarfs.append(dwarf)
    jobs.append(job)
    total_size += 1
    if job != null:
        total_assigned_jobs += 1
