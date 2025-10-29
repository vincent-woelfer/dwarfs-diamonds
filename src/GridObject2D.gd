class_name GridObject2D
extends Node2D


var grid_pos_prev: Vector2i
var grid_pos: Vector2i

var sample_offset: Vector2 = Global.VERT_OFFSET_SMALL

func _init(grid_pos_: Vector2i) -> void:
	grid_pos = grid_pos_
	grid_pos_prev = grid_pos_


func _on_enter_new_grid_pos() -> void:
	pass
	

func _sample_grid_pos() -> bool:
	var new_grid_pos := Global.level.get_cell_at_world_pos(global_position + sample_offset).grid_pos
	if new_grid_pos != grid_pos:
		grid_pos_prev = grid_pos
		grid_pos = new_grid_pos
		_on_enter_new_grid_pos()
		return true

	return false
