@abstract
class_name AbstractJob
extends RefCounted

########################################################################################################################
# Represents a WORKABLE job that dwarfs can be assigned to. Examples: Mining a cell, building a building, etc.

const MAX_REMAINING_TIME_ESTIMATE: float = 60.0 * 5.0 # 5 minutes
const CANT_WORK_TIME: float = MAX_REMAINING_TIME_ESTIMATE

########################################################################################################################
# SHARED VARIABLES
########################################################################################################################
# Currently assigned dwarfs
var assigned_dwarfs: Array[Dwarf] = []

## The cell this job is centered around. E.g. for mining the cell to mine, for building the cell to build on, etc.
var center_cell: Cell

# Only active jobs are listed in job-manager.
# Non-active means completed or aborted and are only used for dwarfs to reference them in their finished-job callback.
var is_active: bool

# Only meaningful after job was archived ( is_active=false )
var success: bool

# Needs to be updated with update_workable_from_poses()
var workable_from_poses: Array[Vector2i] = []


########################################################################################################################
# GENERAL PUBLIC METHODS (not abstract)
########################################################################################################################
## Basic checks whether this job is blocked or ready
func is_workable() -> bool:
	if assigned_dwarfs.size() >= calculate_dwarf_capacity():
		return false
	if workable_from_poses.is_empty():
		return false

	return true


func assign_dwarf(dwarf: Dwarf) -> bool:
	assert(dwarf != null)

	if dwarf in assigned_dwarfs:
		return false
	if assigned_dwarfs.size() >= calculate_dwarf_capacity():
		return false

	Util.array_append_unique_not_null(assigned_dwarfs, dwarf)

	return true


func unassign_dwarf(dwarf: Dwarf) -> void:
	assert(dwarf != null)
	assert(assigned_dwarfs.has(dwarf))
	assigned_dwarfs.erase(dwarf)


## Signals all working dwarfs (also the one finishing this job) that the job is finished.
## ONLY CALL VIA GLOBAL ACTIONS.
func archive_internal(success_: bool) -> void:
	# Ensure this is only triggered once
	if not is_active:
		push_error("Trying to archive job %s but was archived before (is_active=false)" % [self])
		return

	is_active = false
	success = success_

	for dwarf: Dwarf in assigned_dwarfs:
		dwarf._on_job_archived()


########################################################################################################################
# ABSTRACT PUBLIC METHODS
########################################################################################################################
@abstract func get_job_type_name() -> String


## Verifies that all required variables are set for this job
@abstract func verify_variables() -> void


## Generates the list of tasks required to complete this job.
@abstract func generate_tasks() -> Array[Task]


## Number of dwarfs that can work on this job simultaneously
@abstract func calculate_dwarf_capacity() -> int


## Score job - lower is better.
## Unit = seconds (because path time is the default score).
## Returns null if job should not be considered at all
@abstract func score_job_for_dwarf_with_path(dwarf: Dwarf, path: Path) -> ScoredJob


@abstract func update_workable_from_poses() -> void


## Estimates remaining time in seconds. For now only works when dwarf already arrived at job.
## Used for other dwarfs to decide whether to take this job or not.
@abstract func estimate_remaining_time() -> float


@abstract func can_dwarf_do_job_at_all(dwarf: Dwarf) -> bool


## Checks whether this job is a duplicate of another job (by data, not by reference)
@abstract func is_duplicate(other_job: AbstractJob) -> bool


########################################################################################################################
# INTERNAL METHODS
########################################################################################################################
func _init(center_cell_: Cell) -> void:
	assert(center_cell_ != null)

	center_cell = center_cell_
	is_active = true
	assigned_dwarfs = []


########################################################################################################################
# DEBUG
########################################################################################################################
## info[0] = job type string (MINE, BUILD, etc)
## info[1] = status string (BLOCKED, READY, DOING (x/y), ARCHIVED)
## info[2] = status color
func get_debug_info() -> Array:
	var info: Array[Variant] = []
	info.resize(3)

	# Job Type - default. Overridden for some types below
	info[0] = get_job_type_name()

	if not is_active:
		info[1] = "ARCHIVED"
		info[2] = Colors.JOB_COLOR_ARCHIVED
		return info

	# "Status"
	if not is_workable():
		info[1] = "BLOCKED"
		info[2] = Colors.JOB_COLOR_BLOCKED
	else:
		if assigned_dwarfs.is_empty():
			info[1] = "READY"
			info[2] = Colors.JOB_COLOR_READY
		else:
			info[1] = "DOING %d/%d" % [assigned_dwarfs.size(), calculate_dwarf_capacity()]
			info[2] = Colors.JOB_COLOR_DOING

	return info


func _to_string() -> String:
	var info := get_debug_info()
	var color: Color = info[2]
	color = Colors.to_print_color(color)

	# Format example: Job(MINE - READY @Vector2(3,4))
	return Util.color_string("Job(%s - %s @%s)" % [info[0], info[1], center_cell.grid_pos], color)
