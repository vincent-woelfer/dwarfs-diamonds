class_name BuildingPreview
extends GridObject2D


var building_data: BuildingData
var is_valid_placement: bool = true

const modulate_valid: Color = Color(1, 1, 1, 0.5)
const modulate_invalid: Color = Color(1, 0.3, 0.3, 0.5)


func setup(grid_pos_: Vector2i, sample_offset_: Vector2 = Global.VERT_OFFSET_SMALL) -> void:
	super.setup(grid_pos_, sample_offset_)


func _ready() -> void:
	self.modulate = modulate_valid


func update_validity(is_valid: bool) -> void:
	is_valid_placement = is_valid
	if is_valid_placement:
		self.modulate = modulate_valid
	else:
		self.modulate = modulate_invalid


# Callback
func _on_new_cell_entered(new_cell: Cell) -> void:
	pass
