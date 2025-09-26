extends Control

@onready var start_bgm = $StartBGM
@onready var login_panel = $LoginPanel
@onready var profile_dropdown = $LoginPanel/OptionButton
@onready var new_profile_input = $LoginPanel/LineEdit
@onready var classroom_id_input = $LoginPanel/LineEdit2
@onready var password_input = $LoginPanel/LineEdit3
@onready var login_button = $LoginPanel/Button
@onready var refresh_button = $LoginPanel/Button2
@onready var blackout = $BlackOverlay  # The black ColorRect overlay
@onready var start_button = $Play      # Your main menu/play/start button (named 'Play' in your scene)
@onready var progress_bar = $ProgressBar 
var profiles_folder = "user://profiles/"
var current_profile = ""

func _ready():
	PersistentUI.set_coin_display_visibility(false)
	CarbonFootprintUI.set_footprint_display_visibility(false)
	start_bgm.play()
	start_bgm.connect("finished", Callable(self, "_on_start_bgm_finished"))

	# Hide all visible UI except black overlay and login panel
	for child in get_children():
		if child != blackout and child != login_panel and child is CanvasItem:
			child.visible = false
	blackout.visible = true
	login_panel.visible = true
	start_button.visible = false
	progress_bar.visible = false
	# Center login panel (if not already set in editor)
	login_panel.anchor_left = 0.5
	login_panel.anchor_right = 0.5
	login_panel.anchor_top = 0.5
	login_panel.anchor_bottom = 0.5
	login_panel.set_position(Vector2(
		(get_viewport_rect().size.x - login_panel.size.x) / 2,
		(get_viewport_rect().size.y - login_panel.size.y) / 2
	))
	setup_login_panel()

func _on_start_bgm_finished():
	start_bgm.play()

func setup_login_panel():
	if not DirAccess.dir_exists_absolute(profiles_folder):
		DirAccess.open("user://").make_dir_recursive("profiles")
	login_button.pressed.connect(_on_login_button_pressed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	load_profiles()
	login_button.disabled = true
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
	if index == 0:
		current_profile = ""
		new_profile_input.editable = true
		new_profile_input.text = ""
	else:
		current_profile = profile_dropdown.get_item_text(index)
		new_profile_input.editable = false
		new_profile_input.text = current_profile
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

func _on_input_changed(_text: String = ""):
	validate_form()

func validate_form():
	var has_profile = (profile_dropdown.selected > 0) or (new_profile_input.text.strip_edges() != "")
	var has_classroom = classroom_id_input.text.strip_edges() != ""
	var has_password = password_input.text.strip_edges() != ""
	login_button.disabled = not (has_profile and has_classroom and has_password)

func _on_login_button_pressed():
	var profile_name = ""
	if profile_dropdown.selected > 0:
		profile_name = profile_dropdown.get_item_text(profile_dropdown.selected)
	else:
		profile_name = new_profile_input.text.strip_edges()
	var classroom_id = classroom_id_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	if profile_name == "":
		show_error("Please enter a profile name or select existing profile")
		return
	login_button.disabled = true
	login_button.text = "Validating..."
	validate_classroom_with_server(profile_name, classroom_id, password)

func validate_classroom_with_server(profile_name: String, classroom_id: String, password: String):
	validate_classroom_dummy(profile_name, classroom_id, password)

func validate_classroom_dummy(profile_name: String, classroom_id: String, password: String):
	await get_tree().create_timer(1.0).timeout
	var dummy_classrooms = {
		"MATH101": "password123",
		"SCI202": "science2024"
	}
	if classroom_id in dummy_classrooms:
		if dummy_classrooms[classroom_id] == password:
			_on_validation_success(profile_name, classroom_id, password)
		else:
			_on_validation_failed("Incorrect password for classroom: " + classroom_id)
	else:
		_on_validation_failed("Classroom '" + classroom_id + "' does not exist")

func _on_validation_success(profile_name: String, classroom_id: String, password: String):
	create_or_update_profile(profile_name, classroom_id, password)
	current_profile = profile_name
	initialize_game_with_profile(profile_name, classroom_id, password)
	login_panel.visible = false
	blackout.visible = false
	# Show Start button and main UI (show only visual nodes)
	for child in get_children():
		if child != login_panel and child != blackout and child != progress_bar and child is CanvasItem:
			child.visible = true
	start_button.visible = true
	start_button.grab_focus()

func _on_validation_failed(error_message: String):
	login_button.disabled = false
	login_button.text = "Join Game"
	show_error(error_message)

func create_or_update_profile(profile_name: String, classroom_id: String, _password: String):
	var profile_dir = profiles_folder + profile_name + "/"
	if not DirAccess.dir_exists_absolute(profile_dir):
		DirAccess.open("user://").make_dir_recursive("profiles/" + profile_name)
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
	CarbonFootprintManager.set_profile_data(profile_name, classroom_id, password)
	AvatarManager.set_profile(profile_name)
	LevelCompletionManager.set_profile(profile_name)

func show_error(message: String):
	print("Error: ", message)
	# You can create a popup dialog here later
