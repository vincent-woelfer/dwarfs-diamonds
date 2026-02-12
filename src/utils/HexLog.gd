class_name HexLog

########################################################################################################################
# Printing / Logging
########################################################################################################################
const BANNER_WIDTH: int = 64
const BANNER_CHAR: String = "="

# Print Throttle Intervalls
const NO_JOB_INTERVALL := 3.0
const NO_PATH_AP_INTERVALL := 3.0

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


## Prints text at a limited rate (to avoid flooding the console).
## Returns true if the text was printed, false otherwise.
## ref_object is used to distinguish different callers, e.g. should be the dwarf and not the JobManager.
static var _last_print_times: Dictionary[String, float] = {}
static func print_throttled(ref_object: Object, text: String, min_interval: float = 1.0, color: Color = Color.WHITE) -> bool:
	var stack := get_stack()
	var call_info: Dictionary = stack[1] if stack.size() > 1 else {}
	var instance_id := ref_object.get_instance_id() if ref_object != null else 0
	var key: String = "%s:%d:%d" % [call_info.get("source", "unknown"), call_info.get("line", -1), instance_id]
	
	var now: float = Util.now()
	var last_time: float = _last_print_times.get(key, -INF)

	if now - last_time >= min_interval:
		HexLog.print(text, color)
		_last_print_times[key] = now
		return true
		
	return false
 

## Prints with color formatting
static func print(text: String, color: Color = Color.WHITE) -> void:
	print_rich(Util.color_string(text, color))


########################################################################################################################
# INTERNAL API
########################################################################################################################
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
