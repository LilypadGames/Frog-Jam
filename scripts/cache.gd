extends Node

# internal
var path: String = "res://data"
var lang: Dictionary = {}
var lang_files: Array[String] = ["en_us"]
var sfx: Dictionary = {}
var sfx_files: Array[String] = ["interact", "inventory"]

# cache registry and data
func _ready():
	# sounds
	for file in sfx_files:
		sfx[file] = _parse_json(path + "/sfx/" + file + ".json")

	# language
	for file in lang_files:
		lang[file] = _parse_json(path + "/lang/" + file + ".json")

# parse data from specified json file
func _parse_json(file_path: String):
	# file doesn't exist
	if not FileAccess.file_exists(file_path):
		prints("ERROR: Attempting to access", file_path)
		return

	# open file and parse data
	var data_file = FileAccess.open(file_path, FileAccess.READ)
	var parsed_data = JSON.parse_string(data_file.get_as_text())

	# parsed data isnt formatted correctly
	if not parsed_data is Dictionary:
		prints("ERROR: Attempting to parse", file_path)
		return

	# successfuly parsed
	return parsed_data

# abstracts paths to return a single output from an array or single string
func one_from(input) -> String:
	if typeof(input) == TYPE_STRING:
		return input
	elif typeof(input) == TYPE_ARRAY:
		randomize()
		return input[randi() % input.size()]
	else:
		return "ERROR"
