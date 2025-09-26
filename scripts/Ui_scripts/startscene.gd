extends Control

@onready var start_bgm = $StartBGM

# Login Panel References
@onready var login_panel = $LoginPanel
@onready var profile_dropdown = $LoginPanel/OptionButton
@onready var new_profile_input = $LoginPanel/LineEdit
@onready var classroom_id_input = $LoginPanel/LineEdit2
@onready var password_input = $LoginPanel/LineEdit3
@onready var login_button = $LoginPanel/Button
@onready var refresh_button = $LoginPanel/Button2

# Profile Management
var profiles_folder = "user://profiles/"
var current_profile = ""

func _ready():
	PersistentUI.set_coin_display_visibility(false)
	CarbonFootprintUI.set_footprint_display_visibility(false)
	start_bgm.play()
	start_bgm.connect("finished", Callable(self, "_on_start_bgm_finished"))
	
	# Setup login panel
	setup_login_panel()

func _on_start_bgm_finished():
	start_bgm.play()

func setup_login_panel():
	# Create profiles folder if it doesn't exist
	if not DirAccess.dir_exists_absolute(profiles_folder):
		DirAccess.open("user://").make_dir_recursive("profiles")
	
	# Connect buttons
	login_button.pressed.connect(_on_login_button_pressed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	
	# Load existing profiles
	load_profiles()
	
	# Initially disable login button
	login_button.disabled = true
	
	# Connect input changes to validate form
	new_profile_input.text_changed.connect(_on_input_changed)
	classroom_id_input.text_changed.connect(_on_input_changed)
	password_input.text_changed.connect(_on_input_changed)
	profile_dropdown.item_selected.connect(_on_profile_selected)

func load_profiles():
	profile_dropdown.clear()
	profile_dropdown.add_item("-- Select Profile --")
	
	var dir = DirAccess.open(profiles_folder)
	if dir:
		dir.list_dir_begin()
		var profile_name = dir.get_next()
		
		while profile_name != "":
			if dir.current_is_dir() and profile_name != "." and profile_name != "..":
				profile_dropdown.add_item(profile_name)
			profile_name = dir.get_next()

func _on_refresh_button_pressed():
	load_profiles()

func _on_profile_selected(index: int):
	if index == 0:  # "-- Select Profile --" selected
		current_profile = ""
		new_profile_input.editable = true
		new_profile_input.text = ""
	else:
		# Existing profile selected
		current_profile = profile_dropdown.get_item_text(index)
		new_profile_input.editable = false
		new_profile_input.text = current_profile
		
		# Load saved classroom data for this profile
		load_profile_classroom_data()
	
	validate_form()

func load_profile_classroom_data():
	var profile_path = profiles_folder + current_profile + "/profile_data.dat"
	if FileAccess.file_exists(profile_path):
		var file = FileAccess.open(profile_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var profile_data = json.data
				classroom_id_input.text = profile_data.get("classroom_id", "")
				# Don't auto-fill password for security

func _on_input_changed(text: String = ""):
	validate_form()

func validate_form():
	var has_profile = (profile_dropdown.selected > 0) or (new_profile_input.text.strip_edges() != "")
	var has_classroom = classroom_id_input.text.strip_edges() != ""
	var has_password = password_input.text.strip_edges() != ""
	
	login_button.disabled = not (has_profile and has_classroom and has_password)

func _on_login_button_pressed():
	# Determine profile name
	var profile_name = ""
	if profile_dropdown.selected > 0:
		profile_name = profile_dropdown.get_item_text(profile_dropdown.selected)
	else:
		profile_name = new_profile_input.text.strip_edges()
	
	var classroom_id = classroom_id_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	# Validate profile name
	if profile_name == "":
		show_error("Please enter a profile name or select existing profile")
		return
	
	# Disable login button and show loading
	login_button.disabled = true
	login_button.text = "Validating..."
	
	# Validate classroom with server
	validate_classroom_with_server(profile_name, classroom_id, password)

func validate_classroom_with_server(profile_name: String, classroom_id: String, password: String):
	# DUMMY VALIDATION - Replace this with real server call later
	validate_classroom_dummy(profile_name, classroom_id, password)

func validate_classroom_dummy(profile_name: String, classroom_id: String, password: String):
	# Simulate server delay
	await get_tree().create_timer(1.0).timeout
	
	# Dummy classroom database
	var dummy_classrooms = {
		"MATH101": "password123",
		"SCI202": "science2024"
	}
	
	print("Checking classroom: ", classroom_id, " with password: ", password)
	
	# Check if classroom exists and password is correct
	if classroom_id in dummy_classrooms:
		if dummy_classrooms[classroom_id] == password:
			# Valid classroom and password
			print("✅ Classroom validation successful!")
			_on_validation_success(profile_name, classroom_id, password)
		else:
			# Wrong password
			print("❌ Wrong password for classroom: ", classroom_id)
			_on_validation_failed("Incorrect password for classroom: " + classroom_id)
	else:
		# Classroom doesn't exist
		print("❌ Classroom not found: ", classroom_id)
		_on_validation_failed("Classroom '" + classroom_id + "' does not exist")

func _on_validation_success(profile_name: String, classroom_id: String, password: String):
	# Create/update profile
	create_or_update_profile(profile_name, classroom_id, password)
	
	# Set current profile for the game session
	current_profile = profile_name
	
	# Initialize game systems with this profile
	initialize_game_with_profile(profile_name, classroom_id, password)
	
	# Hide login panel and start game
	login_panel.visible = false
	start_game()

func _on_validation_failed(error_message: String):
	login_button.disabled = false
	login_button.text = "Join Game"
	show_error(error_message)
	print("❌ Classroom validation failed: ", error_message)

func create_or_update_profile(profile_name: String, classroom_id: String, password: String):
	var profile_dir = profiles_folder + profile_name + "/"
	
	# Create profile directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(profile_dir):
		DirAccess.open("user://").make_dir_recursive("profiles/" + profile_name)
	
	# Save profile data
	var profile_data = {
		"profile_name": profile_name,
		"classroom_id": classroom_id,
		"created_date": Time.get_unix_time_from_system(),
		"last_login": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(profile_dir + "profile_data.dat", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(profile_data))
		file.close()

func initialize_game_with_profile(profile_name: String, classroom_id: String, password: String):
	# Initialize all managers with current profile
	CarbonFootprintManager.set_profile_data(profile_name, classroom_id, password)
	AvatarManager.set_profile(profile_name)
	LevelCompletionManager.set_profile(profile_name)
	
	print("All managers initialized for profile: ", profile_name)

func start_game():
	# Your existing game start logic goes here
	# This is where you'd transition to main menu or game scene
	print("Starting game for profile: ", current_profile)
	# Example: get_tree().change_scene_to_file("res://main_menu.tscn")

func show_error(message: String):
	print("Error: ", message)
	# You can create a popup dialog here later
