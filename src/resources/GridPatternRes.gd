@tool
class_name GridPatternRes
extends Resource

@export var cells: Array[Vector2i] = []


## Get all positions with offset applied. Does not check if in bounds.
func get_positions(offset: Vector2i = Vector2i.ZERO) -> Array[Vector2i]:
	if offset == Vector2i.ZERO:
		return cells
		
	var result: Array[Vector2i] = []
	result.assign(cells.map(func(v: Vector2i) -> Vector2i: return v + offset))
	return result
	
## Only get valid (in bounds) cells.
func get_cells(offset: Vector2i = Vector2i.ZERO) -> Array[Cell]:
	var cells_result: Array[Cell] = []

	for pos in get_positions(offset):
		var cell: Cell = Global.level.get_cell(pos)
		if cell != null:
			cells_result.append(cell)
	return cells_result


########################################################################################################################
# INTERNAL
########################################################################################################################
func _init(cells_: Array[Vector2i] = []) -> void:
	assert(cells_ != null)
	cells = _remove_duplicates(cells_)


func _remove_duplicates(array: Array[Vector2i]) -> Array[Vector2i]:
	var unique_positions: Dictionary[Vector2i, bool] = {}
	for pos in array:
		unique_positions[pos] = true
	return (unique_positions.keys() as Array[Vector2i])
