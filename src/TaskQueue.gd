class_name Task
extends RefCounted

###################################
# VARIABLES
###################################
var _task_queue: Array[Task] = []

########################################################################################################################
# METHODS
########################################################################################################################
func append_end(task: Task) -> void:
	_task_queue.append(task)


func pop_front() -> Task:
	if _task_queue.is_empty():
		return null
	return _task_queue.pop_front()


func size() -> int:
	return _task_queue.size()


func is_empty() -> bool:
	return _task_queue.is_empty()


func clear() -> void:
	_task_queue.clear()


func _to_string() -> String:
	var msg: String = "TaskQueue:\n"
	for task in _task_queue:
		msg += " - %s\n" % task._to_string()
	msg += "\n"
	return msg
