class_name Nav
extends Node2D

var _astar: AStar2D = null

var _cell_connections_to_update: CellPairQueue = CellPairQueue.new()


########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func queue_update_cell(grid_pos: Vector2i) -> void:
	if not Util.is_grid_pos_valid(grid_pos):
		return

	# Queue for connection update with all neighbours
	for n_offset: Vector2i in Util.neighbours_all:
		var neighbor_pos := grid_pos + n_offset
		_cell_connections_to_update.append_bidirectional(grid_pos, neighbor_pos)


## Returns null if no path found
func find_path(start: Vector2i, goal: Vector2i) -> Path:
	var from_id: int = Util.hash(start)
	var to_id: int = Util.hash(goal)

	# Check if both points are in astar and not disabled
	if not (_is_id_enabled(from_id) and _is_id_enabled(to_id)):
		return null

	var path_grid_points: PackedVector2Array = _astar.get_point_path(from_id, to_id, false)
	if path_grid_points.is_empty():
		return null

	return Path.new(path_grid_points)


func find_path_to_one_of(start: Vector2i, goals: Array[Vector2i]) -> Path:
	if goals.is_empty():
		return null

	var from_id: int = Util.hash(start)
	if not _is_id_enabled(from_id):
		return null

	var shortest_path: Path = null
	for goal in goals:
		var to_id: int = Util.hash(goal)
		if not _is_id_enabled(to_id):
			continue

		var path_grid_points: PackedVector2Array = _astar.get_point_path(from_id, to_id, false)
		if path_grid_points.is_empty():
			continue

		var new_path := Path.new(path_grid_points)
		if shortest_path == null or new_path.get_length() < shortest_path.get_length():
			shortest_path = new_path

	return shortest_path


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _init() -> void:
	self.process_priority = Enum.ProcessPriority.NAV


func _ready() -> void:
	_generate_nav_grid()


func _process(delta: float) -> void:
	_update_cell_connections()
	

# Disabled = currently not walkable
# Connections might still be there for disabled cells (might changein future)
func _update_cell_connections() -> void:
	if _cell_connections_to_update.is_empty():
		return

	var start_time := Time.get_ticks_msec()
	var cell_connections := _cell_connections_to_update.size()
	
	while not _cell_connections_to_update.is_empty():
		# Guaranteed that pair is valid positions and not null
		var cell_pair: CellPairQueue.Pair = _cell_connections_to_update.pop_front()

		# Update individual cells -> This is called way to often per cell per frame but whatever for now
		_update_cell_individually(cell_pair.grid_pos_from)
		_update_cell_individually(cell_pair.grid_pos_to)

		# This is only called once per directional pair per frame
		_update_cell_connection(cell_pair)

	# Redraw for debug purposes
	queue_redraw()

	var duration := Time.get_ticks_msec() - start_time
	if duration > 1:
		print("Updated %d nav-connections in: %d ms" % [cell_connections, duration])

	EventBus.Signal_NavUpdated.emit()


func _update_cell_individually(grid_pos: Vector2i) -> void:
	var cell: Cell = Global.level.get_cell(grid_pos)
	var id := cell.get_nav_id()
	_astar.set_point_disabled(id, not cell.is_standable())
	# Currently connections remain if point disabled (might change in future)


## Determines whether to connect or disconnect two cells.
## Determined soley based on their flags and eventually neighbours.
## Attention: Points might be disabled and connections might still be there
func _update_cell_connection(cell_pair: CellPairQueue.Pair) -> void:
	# Unpack pair
	var from: Cell = Global.level.get_cell(cell_pair.grid_pos_from)
	var to: Cell = Global.level.get_cell(cell_pair.grid_pos_to)

	var should_connect := false
	if Util.are_cardinal_neighbours(from.grid_pos, to.grid_pos):
		should_connect = _should_connect_cardinal_neighbours(from, to)
	else:
		should_connect = _should_connect_diagonal_neighbours(from, to)

	# Finally make/break connection
	if should_connect:
		_astar.connect_points(from.get_nav_id(), to.get_nav_id(), false)
	else:
		_astar.disconnect_points(from.get_nav_id(), to.get_nav_id(), false)


func _should_connect_cardinal_neighbours(from: Cell, to: Cell) -> bool:
	# Both must be standable
	if (not from.is_standable()) or (not to.is_standable()):
		return false

	# If Horizontal, always connect
	if from.grid_pos.y == to.grid_pos.y:
		return true

	# === Vertical ===
	var lower_cell := Util.get_lower_cell(from, to)

	# If upwards, we can only go up if the lower cell has a ladder.
	if from == lower_cell:
		return lower_cell.has_ladder

	# If downwards, we can always go down
	else:
		return true
	
	
func _should_connect_diagonal_neighbours(from: Cell, to: Cell) -> bool:
	# Both must be standable
	if (not from.is_standable()) or (not to.is_standable()):
		return false

	# We have to connecting/diagonal cells:
	# 1. The lower connecting/diagonal cell must be solid
	# 2. The upper connecting/diagonal cell must be passable
	# This ensures that we can walk diagonally up and down slopes

	var lower_cell := Util.get_lower_cell(from, to)
	var upper_cell := Util.get_upper_cell(from, to)

	var lower_conn_cell: Cell = upper_cell.get_neighbour(Vector2i(0, 1))
	var upper_conn_cell: Cell = lower_cell.get_neighbour(Vector2i(0, -1))

	# Should always be valid
	assert(lower_conn_cell != null)
	assert(upper_conn_cell != null)

	return lower_conn_cell.is_solid and upper_conn_cell.is_passable()


# Assumes level is already generated
func _generate_nav_grid() -> void:
	var start_time := Time.get_ticks_msec()

	_astar = AStar2D.new()
	var max_dim: int = maxi(Global.LEVEL_WIDTH, Global.LEVEL_HEIGHT)
	_astar.reserve_space(max_dim * max_dim)
	_cell_connections_to_update.clear()

	# Add points
	for x in range(Global.LEVEL_WIDTH):
		for y in range(Global.LEVEL_HEIGHT):
			var grid_pos := Vector2i(x, y)
			var id := Util.hash(grid_pos)

			_astar.add_point(id, grid_pos, 1.0)
			# Setting point disabled is handled in _update_cell_connections

			# Queue for connection update with all neighbours
			for n_offset: Vector2i in Util.neighbours_all:
				var neighbor_pos := grid_pos + n_offset
				_cell_connections_to_update.append_unidirectional(grid_pos, neighbor_pos)

	var duration := Time.get_ticks_msec() - start_time
	HexLog.print_banner_with_text("Created astar with %d points in: %d ms" % [Global.LEVEL_WIDTH * Global.LEVEL_HEIGHT, duration])

	# Call update once
	_update_cell_connections()


## Helper functions
func _is_id_enabled(id: int) -> bool:
	return _astar.has_point(id) and _astar.is_point_disabled(id) == false


########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var debug_show := true

const debug_colors := {
	# Points
	"point_passable": Color(1.0, 0.6, 0.0, 0.6),
	"point_standable": Color(1.0, 0.6, 0.0, 1.0),
	"point_disabled": Color(1.0, 0.6, 0.0, 0.03),

	# Connections
	"connection_unidir": Color(1.0, 1.0, 0.0, 0.6),
	"connection_bidir": Color(1.0, 1.0, 0.0, 1.0),
}

const debug_size_point := 6.0
const debug_size_connection := 3.0

const debug_point_offset := Vector2(0.0, 0.3) * Global.CELL_SIZE_VEC

func _draw() -> void:
	if not _astar or not debug_show:
		return

	# Connections - dont draw from disabled points
	for id in _astar.get_point_ids():
		if _astar.is_point_disabled(id):
			continue

		var draw_world_pos := Util.grid_space_to_world_space_cell_center(_astar.get_point_position(id)) + debug_point_offset
		
		# Draw connections - check if to point is disabled
		for conn_id in _astar.get_point_connections(id):
			if _astar.is_point_disabled(conn_id):
				continue

			var conn_pos := Util.grid_space_to_world_space_cell_center(_astar.get_point_position(conn_id)) + debug_point_offset
			var bidirectional := _astar.are_points_connected(id, conn_id, false) and _astar.are_points_connected(conn_id, id, false)
			var color_actual: Color = debug_colors.get("connection_bidir" if bidirectional else "connection_unidir", Colors.DEFAULT)
			var size_actual := debug_size_connection * (2.0 if bidirectional else 1.0)

			draw_line(draw_world_pos, conn_pos, color_actual, size_actual)


	# Points on top to ensure visibility
	for id in _astar.get_point_ids():
		var draw_world_pos := Util.grid_space_to_world_space_cell_center(_astar.get_point_position(id)) + debug_point_offset
		var cell: Cell = Global.level.get_cell(Util.unhash(id))

		var color_actual: Color
		if _astar.is_point_disabled(id):
			color_actual = debug_colors.get("point_disabled", Colors.DEFAULT)
		elif cell.is_standable():
			color_actual = debug_colors.get("point_standable", Colors.DEFAULT)
		else:
			color_actual = debug_colors.get("point_passable", Colors.DEFAULT)

		# Draw point
		draw_circle(draw_world_pos, debug_size_point, color_actual)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toogle_nav_draw"):
		debug_show = not debug_show
		queue_redraw()
