class_name Task
extends RefCounted

###################################
# ENUM DEFINITIONS
###################################
enum Type {
	# store job and move to one of workable_from cells
	MOVE_TO_JOB,
	# move to specific cell
	MOVE_TO_CELL,
	# mine cell at target_grid_pos
	MINE,
	# construct specified building
	CONSTRUCT,
	# pick up specified item
	PICKUP,
	# perform action at action point
	ACTION_POINT,
	# place torch at target_grid_pos
	PLACE_TORCH,
}

###################################
# SHARED VARIABLES
###################################
var type: Task.Type

# used by all tasks
var target_grid_pos: Vector2i

###################################
# TASK SPECIFIC VARIABLES
###################################
# MOVE_TO_JOB
var job: Job = null

# MOVE_TO_CELL

# MINE

# CONSTRUCT
var building: BuildingBase = null

# PICKUP
var carryable_item: CarryableItemComponent = null

# ACTION_POINT
var action_point: ActionPoint = null

# PLACE_TORCH


########################################################################################################################
# METHODS
########################################################################################################################
func _init(type_: Type) -> void:
	type = type_

###################################
# STATIC FACTORY METHODS
###################################
static func create_move_to_job_task(job_: Job) -> Task:
	var task := Task.new(Task.Type.MOVE_TO_JOB)
	task.target_grid_pos = job_.center_cell.grid_pos
	task.job = job_
	return task

static func create_move_to_cell_task(target_grid_pos_: Vector2i) -> Task:
	var task := Task.new(Task.Type.MOVE_TO_CELL)
	task.target_grid_pos = target_grid_pos_
	return task

static func create_mine_task(target_grid_pos_: Vector2i) -> Task:
	var task := Task.new(Task.Type.MINE)
	task.target_grid_pos = target_grid_pos_
	return task

static func create_construct_task(target_grid_pos_: Vector2i, building_: BuildingBase) -> Task:
	var task := Task.new(Task.Type.CONSTRUCT)
	task.target_grid_pos = target_grid_pos_
	task.building = building_
	return task

static func create_pickup_task(target_grid_pos_: Vector2i, carryable_item_: CarryableItemComponent) -> Task:
	var task := Task.new(Task.Type.PICKUP)
	task.target_grid_pos = target_grid_pos_
	task.carryable_item = carryable_item_
	return task

static func create_action_point_task(target_grid_pos_: Vector2i, action_point_: ActionPoint) -> Task:
	var task := Task.new(Task.Type.ACTION_POINT)
	task.target_grid_pos = target_grid_pos_
	task.action_point = action_point_
	return task

static func create_place_torch_task(target_grid_pos_: Vector2i) -> Task:
	var task := Task.new(Task.Type.PLACE_TORCH)
	task.target_grid_pos = target_grid_pos_
	return task


func _to_string() -> String:
	var print_color := Colors.to_print_color(Colors.TASK_PRINT_COLOR)
	return Util.color_string("Task (%s @%s)" % [Enum.to_str(Task.Type, type), target_grid_pos], print_color)
