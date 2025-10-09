@tool
class_name Nav
extends Node2D

var astar: AStar2D


func _ready() -> void:
	_generate_nav()


func _process(delta: float) -> void:
	pass
	

func _update_cell_walkability(cell: Cell) -> void:
	var grid_pos := cell.grid_pos
	var id := _hash(grid_pos)

	# Add cell as walkable
	if cell.is_walkable:
		if not astar.has_point(id):
			astar.add_point(id, grid_pos, 1.0)
			_connect_cell_with_neighbours(grid_pos)

	# Remove cell as walkable
	else:
		if astar.has_point(id):
			astar.remove_point(id)


func _generate_nav() -> void:
	astar = AStar2D.new()
	var max_dim: int = maxi(Global.LEVEL_WIDTH, Global.LEVEL_HEIGHT)
	astar.reserve_space(max_dim * max_dim)

	# Add points
	for x in range(Global.LEVEL_WIDTH):
		for y in range(Global.LEVEL_HEIGHT):
			var grid_pos := Vector2i(x, y)
			var cell: Cell = Global.level.get_cell(grid_pos)

			if cell.is_walkable:
				var id := _hash(grid_pos)
				astar.add_point(id, grid_pos, 1.0)

	# Connect points
	for x in range(Global.LEVEL_WIDTH):
		for y in range(Global.LEVEL_HEIGHT):
			var grid_pos := Vector2i(x, y)
			var cell: Cell = Global.level.get_cell(grid_pos)

			if not cell.is_walkable:
				continue

			_connect_cell_with_neighbours(grid_pos)


## Assumes cell is already added as a point and is walkable
func _connect_cell_with_neighbours(grid_pos: Vector2i) -> void:
	var id := _hash(grid_pos)

	var neighbor_grid_positions := [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1)
	]

	for n: Vector2i in neighbor_grid_positions:
		var neighbor_pos := grid_pos + n
		var neighbor_cell: Cell = Global.level.get_cell(neighbor_pos)
		if neighbor_cell and neighbor_cell.is_walkable:
			var neighbor_point_id := _hash(neighbor_pos)
			if not astar.are_points_connected(id, neighbor_point_id, true):
				astar.connect_points(id, neighbor_point_id, true)


func _hash(v: Vector2i) -> int:
	# Maps [x,y] -> N, works bidirectionally but only for unsigned integers
	# Based on Szudzik pairing
	# https://www.vertexfragment.com/ramblings/cantor-szudzik-pairing-functions/#szudzik-pairing
	return ((v.x * v.x) + v.x + v.y) if v.x >= v.y else ((v.y * v.y) + v.x)


func _unhash(n: int) -> Vector2i:
	# Reverse of Szudzik pairing (unsigned)
	var sqrt_n := int(floori(sqrt(n)))
	var sq := sqrt_n * sqrt_n
	
	if n - sq < sqrt_n:
		# Case where x < y, so y = sqrt_n
		return Vector2i(n - sq, sqrt_n)
	else:
		# Case where x >= y
		return Vector2i(sqrt_n, n - sq - sqrt_n)
