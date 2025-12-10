@abstract
@tool
class_name DecoBase
extends GridObject2D

static var torch_scene: PackedScene = preload('res://scenes/deco/DecoTorch.tscn')

# Only method this base class provides
func place_in_cell(cell: Cell) -> void:
    assert(cell != null)
    super.setup(cell.grid_pos, Vector2.ZERO)
