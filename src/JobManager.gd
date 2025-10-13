class_name JobManager
extends Node2D

var _jobs: Array[Job] = []


########################################################################
# PUBLIC METHODS
########################################################################



########################################################################
# PRIVATE METHODS
########################################################################
func _init() -> void:
	self.process_priority = Enum.ProcessPriority.JOBS


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass
	

########################################################################
# DEBUG DRAWING
########################################################################
var debug_show := true
const debug_color_point_passable := Color(1.0, 0.6, 0.0, 0.6)

const debug_size_point := 6.0

const debug_offset_downwards := Vector2(0.0, 0.3) * Global.CELL_SIZE_VEC

func _draw() -> void:
	if not debug_show:
		return


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toogle_jobs_draw"):
		debug_show = not debug_show
		queue_redraw()
