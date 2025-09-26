extends Node

var completed_levels: Dictionary = {}

# Profile-based save system
var current_profile: String = ""
var profiles_folder: String = "user://profiles/"

var required_levels: Array = [
	"reforestation_level1",
	"reforestation_level2", 
	"reforestation_level3",
	"reforestation_level4"
]

func _ready():
	# Wait for profile to be set before loading
	pass

# NEW: Set current profile (called from login system)
func set_profile(profile_name: String):
	current_profile = profile_name
	load_completion_data()
	print("LevelCompletionManager: Set profile to ", profile_name)

func mark_level_completed(level_id: String):
	completed_levels[level_id] = true
	save_completion_data()
	print("Level completed:", level_id, " for profile:", current_profile)

func is_level_completed(level_id: String) -> bool:
	return completed_levels.get(level_id, false)

func get_completed_levels() -> Dictionary:
	return completed_levels

func reset_all_completions():
	completed_levels.clear()
	save_completion_data()

func all_levels_completed_locked() -> bool:
	# Check if all required levels are completed
	for level_id in required_levels:
		if not is_level_completed(level_id):
			return false
	return true

# UPDATED: Save completion data to profile folder
func save_completion_data():
	if current_profile == "":
		print("Cannot save level completion: No profile set")
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "level_completion_save.dat"
	
	# Create profile directory if needed
	if not DirAccess.dir_exists_absolute(profile_dir):
		DirAccess.open("user://").make_dir_recursive("profiles/" + current_profile)
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"completed_levels": completed_levels
		}
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Saved level completion for profile: ", current_profile)

# UPDATED: Load completion data from profile folder
func load_completion_data():
	if current_profile == "":
		completed_levels = {}
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "level_completion_save.dat"
	
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
				print("Loaded level completion for profile ", current_profile, ": ", completed_levels.keys())
			else:
				print("Error parsing level completion save file for profile: ", current_profile)
				completed_levels = {}
	else:
		print("No level completion save file found for profile: ", current_profile, " - starting fresh")
		completed_levels = {}
