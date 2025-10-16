class_name MiningComponent
extends Node2D


## Emitted when a cell was completely mined
signal Signal_OnMiningCompleted(grid_pos: Vector2i)

# per second
@export var _mine_speed := 0.5

var _currently_mining_cells: Array[Cell] = []


########################################################################
# PUBLIC METHODS
########################################################################
func start_mining(cell: Cell) -> void:
	if cell in _currently_mining_cells or cell == null or not cell.is_solid:
		return

	_currently_mining_cells.append(cell)


func stop_mining(cell: Cell) -> void:
	if cell in _currently_mining_cells:
		_currently_mining_cells.erase(cell)


func is_currently_mining() -> bool:
	return not _currently_mining_cells.is_empty()

########################################################################
# PRIVATE METHODS
########################################################################
func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	for mining_cell in _currently_mining_cells:
		# Was cell destroyed by other means?
		if not mining_cell.is_solid:
			_currently_mining_cells.erase(mining_cell)
			Signal_OnMiningCompleted.emit(mining_cell.grid_pos)
			continue

		# Actual Mining
		mining_cell.mining_process += _mine_speed * delta
		if mining_cell.mining_process >= 1.0:
			Actions.destroy_cell(mining_cell)

			_currently_mining_cells.erase(mining_cell)
			Signal_OnMiningCompleted.emit(mining_cell.grid_pos)
