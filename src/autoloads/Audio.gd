# No class_name here, the name of the singleton is set in the autoload
extends Node

########################################################################################################################
# SOUNDS
########################################################################################################################
static var sounds: Dictionary[String, AudioStream] = {
	"cell_on_destroy": preload("res://assets/audio/dirt_block_break.mp3"),
    "dwarf_on_landing": preload("res://assets/audio/ouch.wav"),
	"building_placed": preload("res://assets/audio/building_placed.wav"),
	"building_complete": preload("res://assets/audio/building_complete.wav"),
	"hammering_looped": preload("res://assets/audio/hammering_looped.wav"),
	"mining_1_looped": preload("res://assets/audio/mining_1_looped.wav"),
	"mining_2_looped": preload("res://assets/audio/mining_2_looped.wav"),
	"mining_3_looped": preload("res://assets/audio/mining_3_looped.wav"),
	"rubble_impact": preload("res://assets/audio/rubble_impact.wav"),
	"item_placing": preload("res://assets/audio/item_placing.wav"),
	"ohoh_1": preload("res://assets/audio/ohoh_amelie_1.wav"),
	"ohoh_2": preload("res://assets/audio/ohoh_amelie_2.wav"),
	"ohoh_3": preload("res://assets/audio/ohoh_amelie_3.wav"),
	"dispose_trash": preload("res://assets/audio/dispose_trash.wav"),
	"dwarf_walk_1_looped": preload("res://assets/audio/dwarf_walk_1_looped.wav"),
	"building_on_destroy": preload("res://assets/audio/destroy_1.mp3"),
	"gemstone_drop": preload("res://assets/audio/gemstone_drop.wav"),
}

# Relative volume adjustments in dB for each sound, assuming 0.0 as default (no modification, original volume from track)
static var sounds_volume_db: Dictionary[String, float] = {
    "dwarf_on_landing": - 4.0,
	"item_placing": + 8.0,
	"ohoh_1": + 4.0,
	"ohoh_2": + 4.0,
	"ohoh_3": + 4.0,
	"dispose_trash": + 16.0,
}

# General volume adjustment in dB applied to all sounds
static var general_sounds_volume_db: float = 5.0


########################################################################################################################
# PUBLIC API
########################################################################################################################
func play_at_pos(audio_name: String, pos: Vector2) -> AudioStreamPlayer2D:
	return play_at_pos_with_pitch(audio_name, pos, 1.0)

func play_at_pos_with_pitch(audio_name: String, pos: Vector2, pitch: float) -> AudioStreamPlayer2D:
	var stream := _get_audio_stream(audio_name)
	if stream == null:
		return

	var player := _get_free_player()
	player.stream = stream
	player.global_position = pos
	player.pitch_scale = pitch
	player.volume_db = _get_volume_db(audio_name)
	player.play()

	return player


func stop_player(player: AudioStreamPlayer2D) -> void:
	if player == null or player not in _players:
		return

	player.stop()


func update_player_position(player: AudioStreamPlayer2D, new_pos: Vector2) -> void:
	if player == null or player not in _players:
		return

	player.global_position = new_pos

########################################################################################################################
# INTERNAL API
########################################################################################################################
# Pool of audio players to play sounds
var _players: Array[AudioStreamPlayer2D] = []
var _default_number_of_players: int = 4

func _ready() -> void:
	# Pre-allocate a small pool
	for i in range(_default_number_of_players):
		_create_new_player()

	# Cleanup timers every x seconds
	add_child(Util.timer(2.0, _cleanup_idle_players))


func _get_audio_stream(audio_name: String) -> AudioStream:
	if audio_name in sounds:
		return sounds[audio_name]

	push_error("AudioManager: No sound found with name '%s'" % audio_name)
	return null


func _get_free_player() -> AudioStreamPlayer2D:
	# Return idle player or create a new one
	for p in _players:
		if not p.playing:
			return p

	return _create_new_player()


func _create_new_player() -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	add_child(p)
	_players.append(p)
	return p


func _get_volume_db(audio_name: String) -> float:
	return general_sounds_volume_db + sounds_volume_db.get(audio_name, 0.0)

func _cleanup_idle_players() -> void:
	if _players.size() <= _default_number_of_players:
		return

	for p: AudioStreamPlayer2D in _players.duplicate():
		if not p.playing:
			_players.erase(p)
			p.queue_free()

		if _players.size() <= _default_number_of_players:
			break
