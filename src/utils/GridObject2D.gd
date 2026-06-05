@abstract
class_name GridObject2D
extends Node2D

signal Signal_OnNewCellEntered(new_cell: Cell)

# Exposes variables - READ ONLY
var grid_pos_prev: Vector2i:
	get:
		return _grid_pos_prev

var grid_pos: Vector2i:
	get:
		return _grid_pos

var curr_cell: Cell:
	get:
		return _curr_cell

# Internal
var _grid_pos_prev: Vector2i
var _grid_pos: Vector2i
var _curr_cell: Cell

# Truly internal
var _grid_pos_sample_offset: Vector2


func setup_grid_object(grid_pos_: Vector2i, sample_offset_: Vector2 = Util.SAMPLE_OFFSET_VERTICAL_EPSILON) -> void:
	_grid_pos = grid_pos_
	_grid_pos_prev = grid_pos_
	_grid_pos_sample_offset = sample_offset_

	_curr_cell = Global.level.get_cell(grid_pos)


func update_grid_pos(new_grid_pos: Vector2i) -> void:
	_grid_pos_prev = grid_pos
	_grid_pos = new_grid_pos
	_curr_cell = Global.level.get_cell(grid_pos)

	if _grid_pos != _grid_pos_prev:
		Signal_OnNewCellEntered.emit(_curr_cell)


func sample_grid_pos() -> Vector2:
	var cell: Cell = Global.level.sample_cell_at_world_pos(global_position + _grid_pos_sample_offset)
	if cell == null:
		push_error("GridObject2D: %s Tried to sample grid at world position %s but is outside of world! Deleting object!" % [self, global_position + _grid_pos_sample_offset])
		# self.queue_free()
		return Vector2.ZERO

	return cell.grid_pos
