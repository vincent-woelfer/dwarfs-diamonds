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
	while not _cell_connections_to_update.is_empty():
		# Guaranteed that pair is valid positions and not null
		var cell_pair: CellPairQueue.Pair = _cell_connections_to_update.pop_front()

		# Update individual cells -> This is called way to often per cell per frame but whatever for now
		_update_cell_individually(cell_pair.grid_pos_from)
		_update_cell_individually(cell_pair.grid_pos_to)

		# This is only called once per directional pair per frame
		_update_cell_connection(cell_pair)


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
	HexLog.print_banner_with_text("Generating Navigation Grid")

	_astar = AStar2D.new()
	var max_dim: int = maxi(Global.LEVEL_WIDTH, Global.LEVEL_HEIGHT)
	_astar.reserve_space(max_dim * max_dim)

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

	# Call update once
	_update_cell_connections()
