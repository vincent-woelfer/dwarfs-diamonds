class_name DebugPath
extends Node2D

var path: Path

var start_pos: Vector2i = Vector2i(1, 3)


func _ready() -> void:
	path = Path.new()
	add_child(path)

	EventBus.Signal_DebugPathSetStartCell.connect(update_start_pos)


func update_start_pos(new_start_pos: Vector2i) -> void:
	start_pos = new_start_pos
	print("DebugPath: Updated start_pos to ", start_pos)


func _process(delta: float) -> void:
	var nav := Global.level.nav
	if not nav or not nav._astar:
		return

	# Start = fixed
	var from_id: int = Util.hash(start_pos)

	# Goal = mouse
	var mouse_world_pos: Vector2 = Global.camera.mouse_pos_world_space()
	var mouse_grid_pos: Vector2i = (mouse_world_pos / Global.CELL_SIZE).floor()

	path.points_grid_space = nav.find_path(start_pos, mouse_grid_pos)

