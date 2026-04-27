@tool
@abstract
class_name DecoBase
extends GridObject2D

########################################################################################################################
# SETUP
########################################################################################################################
# Only method this base class provides
func place_in_cell(cell: Cell) -> void:
    assert(cell != null)
    setup_grid_object(cell.grid_pos, Vector2.ZERO)

    self.z_index = Enum.ZIndex.DECO
