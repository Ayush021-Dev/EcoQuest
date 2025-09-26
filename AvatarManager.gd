extends Node

signal avatar_changed(new_index)
signal coins_changed(coin_difference)
signal avatar_unlocked(index)

var avatars = [
	{"name": "Default", "sprite_frames_path": "res://avatars/default.tres", "unlocked": true, "price": 0},
	{"name": "Avatar 2", "sprite_frames_path": "res://avatars/avatar2.tres", "unlocked": false, "price": 0},
	{"name": "Avatar 3", "sprite_frames_path": "res://avatars/avatar3.tres", "unlocked": false, "price": 100},
	{"name": "Avatar 4", "sprite_frames_path": "res://avatars/avatar4.tres", "unlocked": false, "price": 150},
	{"name": "Avatar 5", "sprite_frames_path": "res://avatars/avatar5.tres", "unlocked": false, "price": 0},
	{"name": "Miss Earth", "sprite_frames_path": "res://avatars/missearth.tres", "unlocked": false, "price": 300}
]
var current_avatar_index = 0
var total_coins: int = 0

# Profile-based save system
var current_profile: String = ""
var profiles_folder: String = "user://profiles/"

# Audio players declarations
var pause_click_sound: AudioStreamPlayer
var resume_click_sound: AudioStreamPlayer
var main_menu_click_sound: AudioStreamPlayer
var select_click_sound: AudioStreamPlayer
var select_unlock_sound: AudioStreamPlayer
var current_scene_name: String = ""

# Player position storage with backup
var main_scene_player_position: Vector2 = Vector2.ZERO
var previous_valid_position: Vector2 = Vector2.ZERO
var returning_from_level: bool = false
var player_positions = {}

func _ready():
	# Setup audio players for UI sounds
	pause_click_sound = AudioStreamPlayer.new()
	resume_click_sound = AudioStreamPlayer.new()
	main_menu_click_sound = AudioStreamPlayer.new()
	select_click_sound = AudioStreamPlayer.new()
	select_unlock_sound = AudioStreamPlayer.new()
	
	for audio_player in [pause_click_sound, resume_click_sound, main_menu_click_sound, select_click_sound, select_unlock_sound]:
		add_child(audio_player)
		audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
		audio_player.bus = "Master"
	
	# Load actual sound files - replace paths as needed
	pause_click_sound.stream = preload("res://assets/sounds/051_use_item_01.wav")
	resume_click_sound.stream = preload("res://assets/sounds/051_use_item_01.wav")
	main_menu_click_sound.stream = preload("res://assets/sounds/051_use_item_01.wav")
	select_click_sound.stream = preload("res://assets/sounds/051_use_item_01.wav")
	select_unlock_sound.stream = preload("res://assets/sounds/character_unlock.ogg")

# NEW: Set current profile (called from login system)
func set_profile(profile_name: String):
	current_profile = profile_name
	load_all_profile_data()
	print("AvatarManager: Set profile to ", profile_name)

# NEW: Load all profile-specific data
func load_all_profile_data():
	load_avatar_data()
	load_coins_data()
	load_position_data()

# Check if position is valid (not at origin or very close to it)
func is_valid_position(pos: Vector2) -> bool:
	return pos.length() > 10.0

# Save player position from main scene before going to levels
func save_main_scene_player_position():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var player = players[0]
		var new_position = player.global_position
		
		if is_valid_position(new_position):
			if is_valid_position(main_scene_player_position):
				previous_valid_position = main_scene_player_position
			
			main_scene_player_position = new_position
			save_position_data()  # Save to profile
			print("Saved main scene player position: ", main_scene_player_position)
			return true
		else:
			print("Skipping save - player position is invalid: ", new_position)
			return false
	else:
		print("Warning: No player found to save position")
		return false

func auto_save_main_player_position():
	save_main_scene_player_position()

func prepare_scene_change():
	save_main_scene_player_position()

# Restore player position in main scene with fallback logic
func restore_main_scene_player_position():
	var position_to_restore: Vector2
	
	if is_valid_position(main_scene_player_position):
		position_to_restore = main_scene_player_position
		print("Using main saved position: ", position_to_restore)
	elif is_valid_position(previous_valid_position):
		position_to_restore = previous_valid_position
		print("Using previous valid position: ", position_to_restore)
		main_scene_player_position = previous_valid_position
	else:
		print("No valid saved position to restore")
		return false
	
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var player = players[0]
		player.global_position = position_to_restore
		print("Restored player to position: ", position_to_restore)
		return true
	else:
		print("Warning: No player found to restore position")
		return false

func entering_level():
	save_main_scene_player_position()
	returning_from_level = true

func returned_to_main():
	if returning_from_level:
		await get_tree().process_frame
		restore_main_scene_player_position()
		returning_from_level = false

func save_player_position(level_name: String, position: Vector2):
	# Store as dictionary to ensure JSON compatibility
	player_positions[level_name] = {
		"x": position.x,
		"y": position.y
	}
	save_position_data()  # Save to profile

func load_player_to_main_position():
	restore_main_scene_player_position()

func get_player_position(level_name: String) -> Vector2:
	if level_name in player_positions:
		var pos_data = player_positions[level_name]
		
		# Check if it's already a Vector2
		if pos_data is Vector2:
			return pos_data
		# If it's a dictionary (from JSON loading), convert it back to Vector2
		elif pos_data is Dictionary:
			return Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
		else:
			print("Warning: Invalid position data for level: ", level_name)
			return Vector2.ZERO
	return Vector2.ZERO

func get_best_saved_position() -> Vector2:
	if is_valid_position(main_scene_player_position):
		return main_scene_player_position
	elif is_valid_position(previous_valid_position):
		return previous_valid_position
	else:
		return Vector2.ZERO

func set_valid_position(pos: Vector2):
	if is_valid_position(pos):
		if is_valid_position(main_scene_player_position):
			previous_valid_position = main_scene_player_position
		main_scene_player_position = pos
		save_position_data()
		print("Manually set valid position: ", pos)
	else:
		print("Cannot set invalid position: ", pos)

func debug_print_positions():
	print("=== AVATAR MANAGER POSITIONS DEBUG ===")
	print("Profile: ", current_profile)
	print("Main scene position: ", main_scene_player_position, " (valid: ", is_valid_position(main_scene_player_position), ")")
	print("Previous valid position: ", previous_valid_position, " (valid: ", is_valid_position(previous_valid_position), ")")
	print("Best available position: ", get_best_saved_position())
	print("Returning from level: ", returning_from_level)
	print("=====================================")

# Coin management
func get_coins() -> int:
	return total_coins

func add_coins(amount: int):
	total_coins += amount
	save_coins_data()  # Save to profile
	emit_signal("coins_changed", amount)

func spend_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		save_coins_data()  # Save to profile
		emit_signal("coins_changed", -amount)
		return true
	return false

# Avatar management
func get_current_avatar():
	return avatars[current_avatar_index]

func unlock_avatar(index):
	if index < avatars.size():
		avatars[index]["unlocked"] = true
		save_avatar_data()  # Save to profile

func buy_avatar(index) -> bool:
	if index < avatars.size():
		var avatar = avatars[index]
		if not avatar["unlocked"] and spend_coins(avatar["price"]):
			unlock_avatar(index)
			emit_signal("avatar_unlocked", index)
			return true
	return false

func change_avatar(index):
	if index < avatars.size() and avatars[index]["unlocked"]:
		current_avatar_index = index
		save_avatar_data()  # Save to profile
		emit_signal("avatar_changed", index)
		return true
	return false

func get_avatar(index):
	if index < avatars.size():
		return avatars[index]
	return null

func get_avatar_count():
	return avatars.size()

# PROFILE SAVE/LOAD FUNCTIONS

# Save avatar data to profile folder
func save_avatar_data():
	if current_profile == "":
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "avatar_data.dat"
	
	if not DirAccess.dir_exists_absolute(profile_dir):
		DirAccess.open("user://").make_dir_recursive("profiles/" + current_profile)
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"current_avatar_index": current_avatar_index,
			"avatars": avatars
		}
		file.store_string(JSON.stringify(save_data))
		file.close()

# Load avatar data from profile folder
func load_avatar_data():
	if current_profile == "":
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "avatar_data.dat"
	
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var save_data = json.data
				current_avatar_index = save_data.get("current_avatar_index", 0)
				avatars = save_data.get("avatars", avatars)
				print("Loaded avatar data for profile: ", current_profile)

# Save coins data to profile folder
func save_coins_data():
	if current_profile == "":
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "coins_data.dat"
	
	if not DirAccess.dir_exists_absolute(profile_dir):
		DirAccess.open("user://").make_dir_recursive("profiles/" + current_profile)
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"total_coins": total_coins
		}
		file.store_string(JSON.stringify(save_data))
		file.close()

# Load coins data from profile folder
func load_coins_data():
	if current_profile == "":
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "coins_data.dat"
	
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var save_data = json.data
				total_coins = save_data.get("total_coins", 0)
				print("Loaded coins for profile ", current_profile, ": ", total_coins)

# Save position data to profile folder
func save_position_data():
	if current_profile == "":
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "position_data.dat"
	
	if not DirAccess.dir_exists_absolute(profile_dir):
		DirAccess.open("user://").make_dir_recursive("profiles/" + current_profile)
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"main_scene_player_position": {
				"x": main_scene_player_position.x,
				"y": main_scene_player_position.y
			},
			"previous_valid_position": {
				"x": previous_valid_position.x,
				"y": previous_valid_position.y
			},
			"player_positions": player_positions
		}
		file.store_string(JSON.stringify(save_data))
		file.close()

# Load position data from profile folder
func load_position_data():
	if current_profile == "":
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "position_data.dat"
	
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var save_data = json.data
				var main_pos = save_data.get("main_scene_player_position", {})
				main_scene_player_position = Vector2(main_pos.get("x", 0), main_pos.get("y", 0))
				
				var prev_pos = save_data.get("previous_valid_position", {})
				previous_valid_position = Vector2(prev_pos.get("x", 0), prev_pos.get("y", 0))
				
				player_positions = save_data.get("player_positions", {})
				print("Loaded position data for profile: ", current_profile)

# Sound playback functions
func play_pause_click():
	if pause_click_sound.playing:
		pause_click_sound.stop()
	pause_click_sound.play()

func play_resume_click():
	if resume_click_sound.playing:
		resume_click_sound.stop()
	resume_click_sound.play()

func play_main_menu_click():
	if main_menu_click_sound.playing:
		main_menu_click_sound.stop()
	main_menu_click_sound.play()

func play_select_click():
	if select_click_sound.playing:
		select_click_sound.stop()
	select_click_sound.play()

func play_select_unlock():
	if select_unlock_sound.playing:
		select_unlock_sound.stop()
	select_unlock_sound.play()
