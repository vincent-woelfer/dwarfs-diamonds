class_name HexLog

######################################################
# Printing / Logging
######################################################
const BANNER_WIDTH: int = 64
const BANNER_CHAR: String = "="

## Prints a one-line banner
static func print_only_banner() -> void:
	print(BANNER_CHAR.repeat(BANNER_WIDTH))

## Prints text sourounded by a one-line banner
static func print_banner_with_text(string: String) -> void:
	# Souround string with spaces
	string = " " + string + " "

	print(_center_text(string, BANNER_WIDTH, BANNER_CHAR))

## Prints text sourounded by a multi-line banner
static func print_multiline_banner_with_text(string: String) -> void:
	# Souround string with spaces
	string = " " + string + " "

	var banner_line: String = BANNER_CHAR.repeat(BANNER_WIDTH)
	print(banner_line, "\n", _center_text(string, BANNER_WIDTH, BANNER_CHAR), "\n", banner_line)


## Helper function: Centers text within a given width using a given filler character
static func _center_text(text: String, width: int, filler: String) -> String:
	var pad_size_total: int = max(0, (width - text.length()))

	var pad_size_left: int
	var pad_size_right: int
	if pad_size_total % 2 == 0:
		var pad_size: int = int(pad_size_total / 2.0)
		pad_size_left = pad_size
		pad_size_right = pad_size
	else:
		pad_size_left = floori(pad_size_total / 2.0)
		pad_size_right = pad_size_left + 1

	return filler.repeat(pad_size_left) + text + filler.repeat(pad_size_right)
