extends Node
# Carbon Footprint Manager - Singleton for tracking global carbon footprint score
# Lower scores are better (like golf scoring)

signal footprint_changed(footprint_difference: int)

var carbon_footprint: int = 1000  # Starting footprint score

# Profile-based save system
var current_profile: String = ""
var classroom_id: String = ""
var classroom_password: String = ""
var profiles_folder: String = "user://profiles/"

# Simple HTTP test variables
var http_request: HTTPRequest

func _ready():
	setup_http()

# NEW: Set profile data from login system
func set_profile_data(profile_name: String, class_id: String, password: String):
	current_profile = profile_name
	classroom_id = class_id
	classroom_password = password
	
	# Load profile-specific footprint data
	load_footprint_data()
	
	print("CarbonFootprintManager: Set profile to ", profile_name, " in classroom ", class_id)

# Setup HTTP request for testing
func setup_http():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# Send data function - called automatically
func send_data():
	if current_profile == "" or classroom_id == "":
		print("Cannot send data: No profile or classroom set")
		return
		
	var data = {
		"classroom_id": classroom_id,
		"student_name": current_profile,
		"carbon_footprint": carbon_footprint,
		"status": get_footprint_status(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var url = "https://webhook.site/your-unique-url"  # Replace with your webhook URL
	var headers = ["Content-Type: application/json"]
	var json_data = JSON.stringify(data)
	
	print("Sending data: ", json_data)
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("HTTP Request error: ", error)

# Handle response
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	var response_text = body.get_string_from_utf8()
	print("Response code: ", response_code)
	
	if response_code == 200:
		print("✅ DATA SENT SUCCESSFULLY!")
	else:
		print("❌ Failed to send data")

# Get current carbon footprint
func get_footprint() -> int:
	return carbon_footprint

# Add to carbon footprint (positive = worse for environment)
func add_footprint(amount: int):
	var old_footprint = carbon_footprint
	carbon_footprint += amount
	
	# Ensure footprint doesn't go below 0
	carbon_footprint = max(0, carbon_footprint)
	
	var actual_change = carbon_footprint - old_footprint
	
	if actual_change != 0:
		footprint_changed.emit(actual_change)
		save_footprint_data()
		# Send data whenever footprint changes
		send_data()
		
func reduce_footprint(amount: int):
	add_footprint(-amount)

# Set carbon footprint to specific value
func set_footprint(new_footprint: int):
	var old_footprint = carbon_footprint
	carbon_footprint = max(0, new_footprint)
	
	var actual_change = carbon_footprint - old_footprint
	
	if actual_change != 0:
		footprint_changed.emit(actual_change)
		save_footprint_data()
		# Send data whenever footprint changes
		send_data()

# Get footprint status for UI coloring
func get_footprint_status() -> String:
	if carbon_footprint < 800:
		return "excellent"  # Green
	elif carbon_footprint <= 1200:
		return "average"    # Yellow
	else:
		return "high"       # Red

# Get status color
func get_footprint_color() -> Color:
	match get_footprint_status():
		"excellent":
			return Color.GREEN
		"average":
			return Color.YELLOW
		"high":
			return Color.RED
		_:
			return Color.WHITE

# UPDATED: Save footprint data to profile folder
func save_footprint_data():
	if current_profile == "":
		print("Cannot save: No profile set")
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "carbon_footprint_save.dat"
	
	# Create profile directory if needed
	if not DirAccess.dir_exists_absolute(profile_dir):
		DirAccess.open("user://").make_dir_recursive("profiles/" + current_profile)
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"carbon_footprint": carbon_footprint
		}
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Saved carbon footprint for profile: ", current_profile)

# UPDATED: Load footprint data from profile folder
func load_footprint_data():
	if current_profile == "":
		carbon_footprint = 1000
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "carbon_footprint_save.dat"
	
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var save_data = json.data
				carbon_footprint = save_data.get("carbon_footprint", 1000)
				print("Loaded carbon footprint for profile ", current_profile, ": ", carbon_footprint)
			else:
				print("Error parsing carbon footprint save file for profile: ", current_profile)
				carbon_footprint = 1000
	else:
		print("No save file found for profile: ", current_profile, " - using default")
		carbon_footprint = 1000

# Reset footprint to default (for testing or new game)
func reset_footprint():
	set_footprint(1000)
