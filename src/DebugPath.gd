class_name DebugPath
extends Node2D

var path: Path

var start_pos: Vector2i = Vector2i(1, 3)


func _ready() -> void:
	path = Path.new([])
	add_child(path)

	EventBus.Signal_DebugPathGoalCell.connect(update_start_pos)


func update_start_pos(new_start_pos: Vector2i) -> void:
	start_pos = new_start_pos
	print("DebugPath: Updated start_pos to ", start_pos)


func _process(delta: float) -> void:
	var nav := Global.level.nav
	if not nav or not nav.astar:
		return

	# Start = fixed
	var from_id: int = Util.hash(start_pos)

	# Goal = mouse
	var mouse_world_pos: Vector2 = Global.camera.mouse_pos_world_space()
	var mouse_grid_pos: Vector2i = (mouse_world_pos / Global.CELL_SIZE).floor()
	var to_id: int = Util.hash(mouse_grid_pos)
	
	# Check if both points are in astar
	var both_walkable := nav.astar.has_point(from_id) and nav.astar.has_point(to_id)

	if not both_walkable:
		path.points = []
		return

	var path_points := nav.astar.get_point_path(from_id, to_id, false)
	path.points = []
