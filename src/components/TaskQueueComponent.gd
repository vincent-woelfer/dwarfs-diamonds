class_name TaskQueueComponent
extends Node2D

########################################################################################################################
# SIGNALS
########################################################################################################################

########################################################################################################################
# VARIABLES
########################################################################################################################
var _task_queue: Array[Task] = []

# Currently worked on task. is the same as front of _task_queue, popped when completed.
var curr_task: Task = null

# Reference to parent dwarf
@onready var parent: Dwarf = get_parent()

########################################################################################################################
# METHODS PUPLIC!!!!
########################################################################################################################

func add_job(job: Job) -> void:
	if not job:
		push_warning("Tried to add null job to task queue!")
		return

	if not job.is_active:
		push_warning("Tried to add inactive job to task queue!")
		return

	# TODO check if task queue is empty?
	# TODO check if tasks are possible????? E.g. if cell to be mined exists, if building to be constructed exists, etc.
	#      or MOST IMPORTANT if path to target exists?????

	# Generate tasks from job
	var tasks: Array[Task] = job.generate_tasks()

	if tasks.is_empty():
		push_warning("Tried to add job to task queue, but job generated no tasks!")
		return

	# TODO for now add link to job for every task
	for task in tasks:
		task.job_workable_from_access = job

	# Set the last task to finish the job
	# tasks[tasks.size() - 1].set_finishes_job(job)

	append_array_end(tasks)

	print_rich("%s added job %s with %d tasks to task queue" % [parent, job, tasks.size()])
	print_rich(self)


# The task-type is only as an error-detection mechanism.
func finish_current_task(expected_task_type: Task.Type) -> bool:
	if curr_task == null:
		print_rich("%s tried to finish current task but there is no current task!" % [parent])
		return false

	if curr_task.type != expected_task_type:
		print_rich("%s finish_current_task called with expected-type %s but current task is of type %s!" % [parent, Enum.to_str(Task.Type, expected_task_type), Enum.to_str(Task.Type, curr_task.type)])
		return false

	assert(_task_queue.size() > 0)
	assert(curr_task == _task_queue[0])

	# Finish job if applicable
	# TODO MAYBE IMPLEMENT HERE BUT FOR NOW, the job-creator (e.g. building, rubble) handles this directly.
	# if curr_task.finishes_job != null:
		# curr_task.finishes_job.is_active = false

	# Remove from queue
	_task_queue.pop_front()

	print_rich("%s finished task %s" % [parent, curr_task])
	print_rich(self)

	curr_task = null

	return true


func start_next_task() -> bool:
	if has_current_task():
		push_error("Tried to start next task while current task is not null!")
		return false
	if _task_queue.is_empty():
		push_warning("Tried to start next task but task queue is empty!")
		return false

	print_rich("%s starting next task %s" % [parent, _task_queue[0]])
	print_rich(self)

	curr_task = _task_queue[0]
	return true


func has_current_task() -> bool:
	return curr_task != null


########################################################################################################################
# METHODS PUPLIC / PRIVATE ????
########################################################################################################################
func append_end(task: Task) -> void:
	_task_queue.append(task)


func append_array_end(tasks: Array[Task]) -> void:
	_task_queue.append_array(tasks)


# func pop_front() -> Task:
# 	if _task_queue.is_empty():
# 		return null
# 	return _task_queue.pop_front()


func size() -> int:
	return _task_queue.size()


func is_empty() -> bool:
	return _task_queue.is_empty()


func clear() -> void:
	_task_queue.clear()


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _ready() -> void:
	assert(parent != null)
	assert(parent is Dwarf)

	# SIGNALS
	# EventBus.Signal_GlobalCellDestroyed.connect(_on_global_any_cell_mining_completed)


########################################################################################################################
# DEBUG
########################################################################################################################
func _to_string() -> String:
	var msg: String = "TaskQueue:"

	if _task_queue.is_empty():
		msg += " - <empty>\n"
		
	else:
		msg += "\n"
		for task in _task_queue:
			msg += " - %s\n" % task._to_string()
		msg += "\n"

	return msg
