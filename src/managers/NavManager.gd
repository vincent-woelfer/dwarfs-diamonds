class_name NavManager
extends Node2D

var _astar: AStar2D = null

var _cell_connections_to_update: CellPairQueue = CellPairQueue.new()


########################################################################################################################
# PUBLIC METHODS
########################################################################################################################

## Update nav for this cell and all 8 neighbours
func queue_update_cell(grid_pos: Vector2i) -> void:
	# Queue for connection update with all neighbours. Adding twice is not a problem
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


func find_path_to_one_of(start: Vector2i, goals: Array[Vector2i], move_stats: MovementStats) -> Path:
	if goals.is_empty():
		return null

	# Check if start is valid
	var from_id: int = Util.hash(start)
	if not _is_id_enabled(from_id):
		return null

	var best_path: Path = null
	for goal in goals:
		var to_id: int = Util.hash(goal)
		if not _is_id_enabled(to_id):
			continue

		var path_grid_points: PackedVector2Array = _astar.get_point_path(from_id, to_id, false)
		if path_grid_points.is_empty():
			continue

		var new_path := Path.new(path_grid_points)

		# Select best path according to time or length
		var new_path_time := new_path.get_total_time(move_stats)
		var best_path_time := best_path.get_total_time(move_stats) if best_path else INF
		if new_path_time < best_path_time:
			best_path = new_path

	return best_path


func is_cell_enabled(grid_pos: Vector2i) -> bool:
	var id: int = Util.hash(grid_pos)
	return _is_id_enabled(id)

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _ready() -> void:
	self.process_priority = Enum.ProcessPriority.NAV

	# Signals
	EventBus.Signal_DevToogleNavDraw.connect(_dev_toogle_nav_draw)
	_dev_toogle_nav_draw()

	_generate_nav_grid()


func _process(delta: float) -> void:
	if not _cell_connections_to_update.is_empty():
		_update_all_queued_cell_connections()
	

# Disabled = currently not walkable
# Connections might still be there for disabled cells (might changein future)
# Happens at most once per frame
func _update_all_queued_cell_connections() -> void:
	var start_time := Time.get_ticks_msec()
	var num_cell_connections := _cell_connections_to_update.size()

	# Guaranteed that pair is valid positions and not null
	for cell_pair: CellPairQueue.Pair in _cell_connections_to_update.get_all():
		# Unpack pair - guaranteed to be valid positions and not null
		var from: Cell = Global.level.get_cell(cell_pair.grid_pos_from)
		var to: Cell = Global.level.get_cell(cell_pair.grid_pos_to)

		# Update individual cells -> This is called way to often per cell per frame but whatever for now
		_update_cell_is_enabled(from)
		_update_cell_is_enabled(to)
		
		_update_cell_connection_pair(from, to)

		# Reset cell nav-flag
		from._queued_nav_update = false
		to._queued_nav_update = false

	# Reset Queue
	_cell_connections_to_update.clear()

	# Redraw for debug purposes
	_debug_draw_proxy_relative.queue_redraw()

	var duration := Time.get_ticks_msec() - start_time
	if duration > 1:
		HexLog.print("Nav   => Updated %d nav-connections in: %d ms" % [num_cell_connections, duration], Colors.NAV_IMPORTANT_PRINT_COLOR)

	EventBus.Signal_NavUpdated.emit()


func _update_cell_is_enabled(cell: Cell) -> void:
	var id := cell.get_nav_id()

	var should_be_enabled := cell.is_standable(true) and cell.is_passable()

	# Currently connections remain if point disabled (but are implicietly disabled too)
	_astar.set_point_disabled(id, not should_be_enabled)


## Determines whether to connect or disconnect two cells.
## Determined soley based on their flags and eventually neighbours.
## Attention: Points are only disabled and internal a-starconnections are not deleted
func _update_cell_connection_pair(from_cell: Cell, to_cell: Cell) -> void:
	_update_cell_connection_unidirectional(from_cell, to_cell)
	_update_cell_connection_unidirectional(to_cell, from_cell)


func _update_cell_connection_unidirectional(from: Cell, to: Cell) -> void:
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
	if (not from.is_standable(true)) or (not to.is_standable(true)):
		return false

	# If Horizontal, always connect
	if from.grid_pos.y == to.grid_pos.y:
		return true

	# === Vertical ===
	var lower_cell := Util.get_lower_cell(from, to)

	# If upwards, we can only go up if the lower cell has a ladder.
	if from == lower_cell:
		return lower_cell.buildings.has_ladder()

	# If downwards, we can always go down
	else:
		return true
	
	
func _should_connect_diagonal_neighbours(from: Cell, to: Cell) -> bool:
	# Both must be standable (implies passable)
	if (not from.is_standable()) or (not to.is_standable()):
		return false

	# We have two connecting/diagonal cells:
	# 1. The lower connecting/diagonal cell must be solid
	# 2. The upper connecting/diagonal cell must be passable
	# This ensures that we can walk diagonally up and down slopes
	var lower_cell := Util.get_lower_cell(from, to)
	var upper_cell := Util.get_upper_cell(from, to)

	var below_upper_cell: Cell = upper_cell.get_neighbour(Global.VEC_DOWN)
	var above_lower_cell: Cell = lower_cell.get_neighbour(Global.VEC_UP)

	# Should always be valid
	assert(below_upper_cell != null)
	assert(above_lower_cell != null)

	return above_lower_cell.is_passable()


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
			# Setting point disabled is handled in _update_all_queued_cell_connections

			# Queue for connection update with all neighbours
			for n_offset: Vector2i in Util.neighbours_all:
				var neighbor_pos := grid_pos + n_offset
				_cell_connections_to_update.append_unidirectional(grid_pos, neighbor_pos)

	var duration := Time.get_ticks_msec() - start_time
	HexLog.print_banner_with_text("Created astar with %d points in: %d ms" % [Global.LEVEL_WIDTH * Global.LEVEL_HEIGHT, duration])

	# Call update once
	_update_all_queued_cell_connections()


## Helper functions
func _is_id_enabled(id: int) -> bool:
	return _astar.has_point(id) and _astar.is_point_disabled(id) == false


########################################################################################################################
# DEBUG DRAWING
########################################################################################################################
var _debug_draw_proxy_relative := DebugDrawProxy.new(self )

const debug_colors := {
	# Points
	"point_passable": Color(1.0, 0.6, 0.0, 0.6),
	"point_standable": Color(1.0, 0.6, 0.0, 1.0),
	"point_disabled": Color(1.0, 0.0, 0.0, 0.0), # Transparent

	# Connections
	"connection_unidir": Color(1.0, 1.0, 0.0, 0.8),
	"connection_bidir": Color(0.6, 1.0, 0.0, 0.8),
}

const debug_size_point := 5.0
const debug_width_connection_uni := 3.0
const debug_width_connection_bi := 3.0
const debug_arrow_length := 15.0
const debug_arrow_width := 10.0

# Downward from cell-center
const debug_point_offset := Vector2(0.0, 0.4) * Global.CELL_SIZE_VEC

func _debug_draw_in_ui_relative(ui_layer: CanvasItem) -> void:
	if not _astar:
		return

	# Connections - dont draw from disabled points.
	# Connections are drawn twice for bidirectional ones, but whatever
	for from_id in _astar.get_point_ids():
		if _astar.is_point_disabled(from_id):
			continue

		var from_pos := Util.grid_to_world_cell_center(_astar.get_point_position(from_id)) + debug_point_offset
		
		# Draw connections - but only if to-point is not disabled
		for to_id in _astar.get_point_connections(from_id):
			if _astar.is_point_disabled(to_id):
				continue

			var to_pos := Util.grid_to_world_cell_center(_astar.get_point_position(to_id)) + debug_point_offset
			var towards_to: bool = _astar.are_points_connected(from_id, to_id, false)
			var towards_from: bool = _astar.are_points_connected(to_id, from_id, false)
			var bidirectional := towards_from and towards_to
			var color_actual: Color = debug_colors.get("connection_bidir" if bidirectional else "connection_unidir", Colors.FALLBACK_COLOR)

			# Smaller for unidirectional
			var size_actual := debug_width_connection_bi if bidirectional else debug_width_connection_uni

			ui_layer.draw_line(from_pos, to_pos, color_actual, size_actual)

			# Directional arrows - towards from_pos
			if towards_to:
				_draw_arrow(ui_layer, from_pos, to_pos, color_actual)
			if towards_from:
				_draw_arrow(ui_layer, to_pos, from_pos, color_actual)

	# Points on top to ensure visibility
	for from_id in _astar.get_point_ids():
		var point_pos := Util.grid_to_world_cell_center(_astar.get_point_position(from_id)) + debug_point_offset
		var cell: Cell = Global.level.get_cell(Util.unhash(from_id))

		var color_actual: Color
		if _astar.is_point_disabled(from_id):
			color_actual = debug_colors.get("point_disabled", Colors.FALLBACK_COLOR)
		elif cell.is_standable():
			color_actual = debug_colors.get("point_standable", Colors.FALLBACK_COLOR)
		else:
			color_actual = debug_colors.get("point_passable", Colors.FALLBACK_COLOR)

		# Draw point
		ui_layer.draw_circle(point_pos, debug_size_point, color_actual)


func _draw_arrow(ui_layer: CanvasItem, from_pos: Vector2, to_pos: Vector2, color: Color) -> void:
	var dir_vector := (to_pos - from_pos).normalized()
	var perp_vector := Vector2(-dir_vector.y, dir_vector.x)

	var arrowtip_point := to_pos - dir_vector * debug_size_point
	var left_point := arrowtip_point - dir_vector * debug_arrow_length + perp_vector * debug_arrow_width
	var right_point := arrowtip_point - dir_vector * debug_arrow_length - perp_vector * debug_arrow_width
	ui_layer.draw_colored_polygon([arrowtip_point, left_point, right_point], color)


func _dev_toogle_nav_draw() -> void:
	_debug_draw_proxy_relative.visible = EventBus.dev_draw_nav
	_debug_draw_proxy_relative.queue_redraw()
