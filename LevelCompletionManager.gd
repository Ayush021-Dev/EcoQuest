extends Node

var completed_levels: Dictionary = {}
var save_file_path: String = "user://level_completion_save.dat"

func _ready():
	load_completion_data()

func mark_level_completed(level_id: String):
	completed_levels[level_id] = true
	save_completion_data()
	print("Level completed:", level_id)

func is_level_completed(level_id: String) -> bool:
	return completed_levels.get(level_id, false)

func get_completed_levels() -> Dictionary:
	return completed_levels

func reset_all_completions():
	completed_levels.clear()
	save_completion_data()

func save_completion_data():
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"completed_levels": completed_levels
		}
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_completion_data():
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var save_data = json.data
				completed_levels = save_data.get("completed_levels", {})
			else:
				print("Error parsing level completion save file")
				completed_levels = {}
	else:
		completed_levels = {}
