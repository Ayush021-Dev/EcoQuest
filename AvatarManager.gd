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

# Audio players declarations
var pause_click_sound: AudioStreamPlayer
var resume_click_sound: AudioStreamPlayer
var main_menu_click_sound: AudioStreamPlayer
var select_click_sound: AudioStreamPlayer
var select_unlock_sound: AudioStreamPlayer
var current_scene_name: String = ""

# UPDATED: Main scene player position storage
var main_scene_player_position: Vector2 = Vector2.ZERO
var returning_from_level: bool = false

# Player position saving dictionary keyed by level/scene name
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

# UPDATED: Save player position from main scene before going to levels
func save_main_scene_player_position():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var player = players[0]
		main_scene_player_position = player.global_position
		print("Saved main scene player position: ", main_scene_player_position)
		return true
	else:
		print("Warning: No player found to save position")
		return false

# ADDED: For compatibility with existing main.gd calls
func auto_save_main_player_position():
	save_main_scene_player_position()

func prepare_scene_change():
	save_main_scene_player_position()

# UPDATED: Restore player position in main scene
func restore_main_scene_player_position():
	if main_scene_player_position == Vector2.ZERO:
		print("No saved position to restore")
		return false
		
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var player = players[0]
		player.global_position = main_scene_player_position
		print("Restored player to main scene position: ", main_scene_player_position)
		return true
	else:
		print("Warning: No player found to restore position")
		return false

# UPDATED: Call this when entering any level
func entering_level():
	save_main_scene_player_position()
	returning_from_level = true

# UPDATED: Call this when returning to main scene
func returned_to_main():
	if returning_from_level:
		# Small delay to ensure scene is fully loaded
		await get_tree().process_frame
		restore_main_scene_player_position()
		returning_from_level = false

# Keep existing functions but update them
func save_player_position(level_name: String, position: Vector2):
	player_positions[level_name] = position

# DEPRECATED: Use the new functions above instead
func load_player_to_main_position():
	restore_main_scene_player_position()

func get_player_position(level_name: String) -> Vector2:
	if level_name in player_positions:
		return player_positions[level_name]
	return Vector2.ZERO

# Coin management funcs
func get_coins() -> int:
	return total_coins

func add_coins(amount: int):
	total_coins += amount
	emit_signal("coins_changed", amount)

func spend_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		emit_signal("coins_changed", -amount)
		return true
	return false

# Avatar management funcs
func get_current_avatar():
	return avatars[current_avatar_index]

func unlock_avatar(index):
	if index < avatars.size():
		avatars[index]["unlocked"] = true

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
		emit_signal("avatar_changed", index)
		return true
	return false

func get_avatar(index):
	if index < avatars.size():
		return avatars[index]
	return null

func get_avatar_count():
	return avatars.size()

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
