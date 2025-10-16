class_name MiningComponent
extends Node2D


## Emitted when a cell was completely mined
signal Signal_OnMiningCompleted(grid_pos: Vector2i)

# per second
@export var mine_speed: float = 0.5
@export var max_simultaneous_mining_cells: int = 1

var _currently_mining_cells: Array[Cell] = []


########################################################################
# PUBLIC METHODS
########################################################################
func start_mining(cell: Cell) -> void:
	if cell in _currently_mining_cells or cell == null or not cell.is_solid:
		return

	if _currently_mining_cells.size() >= max_simultaneous_mining_cells:
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
func _physics_process(delta: float) -> void:
	for mining_cell in _currently_mining_cells:
		# Was cell destroyed by other means?
		if not mining_cell.is_solid:
			_currently_mining_cells.erase(mining_cell)
			Signal_OnMiningCompleted.emit(mining_cell.grid_pos)
			continue

		# Actual Mining
		mining_cell.mining_process += mine_speed * delta
		if mining_cell.mining_process >= 1.0:
			# Doesnt work because the cell gets destroyed immediately -> deletes job -> on_job_deleted on dwarf gets called before this ever runs
			Actions.destroy_cell(mining_cell)

			_currently_mining_cells.erase(mining_cell)
			Signal_OnMiningCompleted.emit(mining_cell.grid_pos)
