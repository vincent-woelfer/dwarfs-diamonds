class_name Audio
extends Node

static var sounds: Dictionary[String, AudioStream] = {
	"cell_on_destroy": preload("res://assets/audio/dirt_block_break.mp3"),
    "dwarf_on_landing": preload("res://assets/audio/ouch.wav"),
}
