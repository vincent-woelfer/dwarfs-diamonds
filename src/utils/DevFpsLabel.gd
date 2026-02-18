extends RichTextLabel

func _process(_delta: float) -> void:
	# FPS
	var text_fps: String = "FPS: %5.0f" % Engine.get_frames_per_second()

	# Cell under mouse
	var cell: Cell = Global.mouse_pointer.curr_selected_cells[0] if Global.mouse_pointer.curr_selected_cells.size() > 0 else null
	var text_mouse_pos: String = "%s" % (cell.to_string() if cell else "Cell=None")

	text = text_fps + " | " + text_mouse_pos
