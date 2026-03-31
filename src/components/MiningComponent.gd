class_name MiningComponent
extends Node2D

## Emitted when a cell was completely mined by this component
signal Signal_OnMiningCompleted(mined_cell: Cell)

# per second
@export var mining_speed: float = 1.0
@export var max_simultaneous_mining_cells: int = 1

# internal
var _currently_mining_cells: Array[Cell] = []

# Reference to the used audio player
var _audio_player: AudioStreamPlayer2D = null

# TODO add mining tool restrictions (e.g. can only mine stone with pickaxe, etc.)
# TODO add different mining sounds per material but also per miner (e.g. pickaxe sound for pickaxe, etc.)

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func start_mining(cell: Cell) -> bool:
	if cell in _currently_mining_cells or cell == null or not cell.is_solid:
		return false
	if _currently_mining_cells.size() >= max_simultaneous_mining_cells:
		return false

	_currently_mining_cells.append(cell)

	if _audio_player == null:
		var audio_name: String = "mining_%d_looped" % randi_range(1, 3)
		_audio_player = Audio.play_at_pos(audio_name, cell.global_position)

	return true


func stop_mining_cell(cell: Cell) -> void:
	if cell in _currently_mining_cells:
		_currently_mining_cells.erase(cell)

	if _currently_mining_cells.is_empty() and _audio_player != null:
		Audio.stop_player(_audio_player)
		_audio_player = null

func stop_mining_all_cells() -> void:
	_currently_mining_cells.clear()

	if _audio_player != null:
		Audio.stop_player(_audio_player)
		_audio_player = null


func is_currently_mining() -> bool:
	return not _currently_mining_cells.is_empty()


## Can this mining component mine this cell at all?
## Used to filter jobs
func can_mine_at_all(cell: Cell) -> bool:
	if cell == null or not cell.is_solid:
		return false

	# TODO other restrictions

	return true

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _ready() -> void:
	# SIGNALS
	EventBus.Signal_CellDestroyed.connect(_on_global_any_cell_mining_completed)


## Called by Signal_CellMiningCompleted for EVERY mined cell in the game
func _on_global_any_cell_mining_completed(mined_cell: Cell) -> void:
	# Check if this component was mining that cell
	if mined_cell in _currently_mining_cells:
		stop_mining_cell(mined_cell)
		Signal_OnMiningCompleted.emit(mined_cell)

		
func _physics_process(delta: float) -> void:
	for mining_cell in _currently_mining_cells:
		# Was cell destroyed by other means? This should NOT happen since we catch this with the global signal, but just in case
		if not mining_cell.is_solid:
			assert(false)
			stop_mining_cell(mining_cell)
			continue

		# Actual Mining
		mining_cell.increase_mining_process(mining_speed * delta)
