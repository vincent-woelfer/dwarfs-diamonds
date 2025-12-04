@abstract
class_name GridObject2D
extends Node2D


var grid_pos_prev: Vector2i
var grid_pos: Vector2i
var curr_cell: Cell

var sample_offset: Vector2

func setup(grid_pos_: Vector2i, sample_offset_: Vector2 = Global.VERT_OFFSET_SMALL) -> void:
	grid_pos = grid_pos_
	grid_pos_prev = grid_pos_
	sample_offset = sample_offset_

	curr_cell = Global.level.get_cell(grid_pos)


func update_grid_pos(new_grid_pos: Vector2i) -> void:
	grid_pos_prev = grid_pos
	grid_pos = new_grid_pos
	curr_cell = Global.level.get_cell(grid_pos)

	if grid_pos != grid_pos_prev:
		_on_new_cell_entered(curr_cell)
		

func sample_grid_pos() -> Vector2:
	return Global.level.sample_cell_at_world_pos(global_position + sample_offset).grid_pos


# Callback
func _on_new_cell_entered(new_cell: Cell) -> void:
	pass
