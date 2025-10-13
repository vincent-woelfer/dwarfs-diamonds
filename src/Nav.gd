class_name Nav
extends Node2D

var _astar: AStar2D = null

var _cell_connections_to_update: CellPairQueue = CellPairQueue.new()


func _init() -> void:
	self.process_priority = Enum.ProcessPriority.NAV


func _ready() -> void:
	_generate_nav_grid()


# Disabled = currently not walkable
# Connections might still be there for disabled cells (might changein future)

func _process(delta: float) -> void:
	if not _astar:
		return

	_update_cell_connections()
	

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
	print("Updated %d nav-connections in: %d ms" % [cell_connections, duration])


func _update_cell_individually(grid_pos: Vector2i) -> void:
	var cell: Cell = Global.level.get_cell(grid_pos)
	var id := cell.get_nav_id()
	_astar.set_point_disabled(id, not cell.is_standable())

	# Currently connections remain if disabled (might change in future)


## Determines whether to connect or disconnect two cells.
## Determined soley based on their flags and eventually neighbours.
## Attention: Points might be disabled and connections might still be there
func _update_cell_connection(cell_pair: CellPairQueue.Pair) -> void:
	# Unpack pair
	var from: Cell = Global.level.get_cell(cell_pair.grid_pos_from)
	var to: Cell = Global.level.get_cell(cell_pair.grid_pos_to)

	var should_connect := false

	# Cardinal neighbours
	if Util.are_cardinal_neighbours(from.grid_pos, to.grid_pos):
		should_connect = from.is_standable() and to.is_standable()

	# Diagonal neighbours
	else:
		# TODO
		pass

	# Finally make/break connection
	if should_connect:
		_astar.connect_points(from.get_nav_id(), to.get_nav_id(), false)
	else:
		_astar.disconnect_points(from.get_nav_id(), to.get_nav_id(), false)


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


########################################################################
# DEBUG DRAWING
########################################################################
var debug_show := true
const debug_color_point_passable := Color(1.0, 0.6, 0.0, 0.6)
const debug_color_point_standable := Color(1.0, 0.6, 0.0, 1.0)
const debug_color_connection_unidir := Color(1.0, 1.0, 0.0, 0.6)
const debug_color_connection_bidir := Color(1.0, 1.0, 0.0, 1.0)

const debug_size_point := 6.0
const debug_size_connection := 3.0

const debug_offset_downwards := Vector2(0.0, 0.3) * Global.CELL_SIZE_VEC

func _draw() -> void:
	if not _astar or not debug_show:
		return

	# Connections
	for id in _astar.get_point_ids():
		if _astar.is_point_disabled(id):
			continue

		var draw_world_pos := Util.grid_space_to_world_space_cell_center(_astar.get_point_position(id)) + debug_offset_downwards
		
		# Draw connections
		for conn_id in _astar.get_point_connections(id):
			var conn_pos := Util.grid_space_to_world_space_cell_center(_astar.get_point_position(conn_id)) + debug_offset_downwards
			var bidirectional := _astar.are_points_connected(id, conn_id, false) and _astar.are_points_connected(conn_id, id, false)
			var color_actual := debug_color_connection_bidir if bidirectional else debug_color_connection_unidir
			var size_actual := debug_size_connection * (2.0 if bidirectional else 1.0)

			draw_line(draw_world_pos, conn_pos, color_actual, size_actual)


	# Points on top to ensure visibility
	for id in _astar.get_point_ids():
		if _astar.is_point_disabled(id):
			continue

		var draw_world_pos := Util.grid_space_to_world_space_cell_center(_astar.get_point_position(id)) + debug_offset_downwards
		var cell: Cell = Global.level.get_cell(Util.unhash(id))
		var color_actual := debug_color_point_standable if cell.is_standable() else debug_color_point_passable

		# Draw point
		draw_circle(draw_world_pos, debug_size_point, color_actual)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toogle_nav_draw"):
		debug_show = not debug_show
		queue_redraw()
