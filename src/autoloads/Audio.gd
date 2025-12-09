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
}


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
	player.play()

	return player


func stop_player(player: AudioStreamPlayer2D) -> void:
	if player == null or player not in _players:
		return

	player.stop()


########################################################################################################################
# INTERNAL API
########################################################################################################################
# Pool of audio players to play sounds
var _players: Array[AudioStreamPlayer2D] = []

func _ready() -> void:
	# Pre-allocate a small pool
	for i in 4:
		_create_new_player()


func _get_audio_stream(audio_name: String) -> AudioStream:
	if audio_name in sounds:
		return sounds[audio_name]

	push_error("AudioManager: No sound found with name '%s'" % audio_name)
	return null


# TODO maybe cleanup players that are not used after a while
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
