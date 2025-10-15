class_name DebugPath
extends Node2D


## This is not a child of Path, it contains a path and manages it

var start_pos: Vector2i = Vector2i(1, 3)
var end_pos: Vector2i = Vector2i.MIN
# Vector2i.MIN is invalid position, means no end pos set

var path: Path = null

func _ready() -> void:
	EventBus.Signal_DebugPathSetStartCell.connect(update_start_pos)
	EventBus.Signal_MouseHoveredCellChanged.connect(on_mouse_hovered_cell_changed)


func update_start_pos(new_start_pos: Vector2i) -> void:
	print("DebugPath: Updated start_pos to ", start_pos)
	start_pos = new_start_pos
	update()

func on_mouse_hovered_cell_changed(new_cell: Cell) -> void:
	if new_cell == null:
		end_pos = Vector2i.MIN
	else:
		end_pos = new_cell.grid_pos

	update()


func update() -> void:
	# Free old path
	if path:
		path.queue_free()

	var nav := Global.level.nav
	if not nav or not nav._astar or end_pos == Vector2i.MIN:
		return

	path = nav.find_path(start_pos, end_pos)
	if path:
		path.color = Color.GREEN
		add_child(path)
