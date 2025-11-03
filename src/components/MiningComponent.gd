class_name MiningComponent
extends Node2D


## Emitted when a cell was completely mined by this component
signal Signal_OnMiningCompleted(mined_cell: Cell)

# per second
@export var mine_speed: float = 0.5
@export var max_simultaneous_mining_cells: int = 1

var _currently_mining_cells: Array[Cell] = []


########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func start_mining(cell: Cell) -> void:
	if cell in _currently_mining_cells or cell == null or not cell.is_solid:
		return

	if _currently_mining_cells.size() >= max_simultaneous_mining_cells:
		return

	_currently_mining_cells.append(cell)


func stop_mining_cell(cell: Cell) -> void:
	if cell in _currently_mining_cells:
		_currently_mining_cells.erase(cell)

func stop_mining() -> void:
	_currently_mining_cells.clear()


func is_currently_mining() -> bool:
	return not _currently_mining_cells.is_empty()


########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _ready() -> void:
	# SIGNALS
	EventBus.Signal_CellMiningCompleted.connect(_on_cell_mining_completed)


## Called by Signal_CellMiningCompleted for EVERY mined cell in the game
func _on_cell_mining_completed(mined_cell: Cell) -> void:
	# Check if this component was mining that cell
	if mined_cell in _currently_mining_cells:
		Signal_OnMiningCompleted.emit(mined_cell)

	_currently_mining_cells.erase(mined_cell)


func _physics_process(delta: float) -> void:
	for mining_cell in _currently_mining_cells:
		# Was cell destroyed by other means? This should NOT happen
		if not mining_cell.is_solid:
			assert(false, "MiningComponent: Cell %s being mined but is no longer solid!" % mining_cell.grid_pos)
			_currently_mining_cells.erase(mining_cell)
			continue

		# Actual Mining
		mining_cell.mining_process += mine_speed * delta
		if mining_cell.mining_process >= 1.0:
			# This in turn emits Signal_CellMiningCompleted which this and all other MiningComponents listen to
			Actions.destroy_cell(mining_cell)
