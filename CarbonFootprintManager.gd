extends Node
# Carbon Footprint Manager - Sends data to webhook for leaderboards

signal footprint_changed(footprint_difference: int)

var carbon_footprint: int = 1000  # Starting footprint score

# Profile-based save system
var current_profile: String = ""
var classroom_id: String = ""
var classroom_password: String = ""
var profiles_folder: String = "user://profiles/"

# Webhook URL - CHANGE THIS TO YOUR WEBHOOK
var webhook_url: String = "https://webhook.site/e1bd9b38-84c0-4ef0-a218-5d3781834d9b"

# HTTP request
var http_request: HTTPRequest

func _ready():
	setup_http()

# Setup HTTP request
func setup_http():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# Set profile data from login system
func set_profile_data(profile_name: String, class_id: String, password: String):
	current_profile = profile_name
	classroom_id = class_id
	classroom_password = password
	
	load_footprint_data()
	send_data()
	
	print("Profile set: ", profile_name, " in classroom ", class_id)

# Send data to webhook - SIMPLE JSON FORMAT
func send_data():
	if current_profile == "" or classroom_id == "":
		print("Cannot send: No profile or classroom")
		return
	
	# Simple JSON data for your leaderboard
	var data = {
		"student_name": current_profile,
		"classroom_id": classroom_id,
		"carbon_footprint": carbon_footprint,
		"status": get_footprint_status(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var headers = ["Content-Type: application/json"]
	var json_data = JSON.stringify(data)
	
	print("Sending to webhook: ", json_data)
	
	var error = http_request.request(webhook_url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("Request failed: ", error)

# Handle response
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	var response_text = body.get_string_from_utf8()
	print("Response: ", response_code, " - ", response_text)
	
	if response_code == 200:
		print("✅ Data sent successfully!")
	else:
		print("❌ Failed to send data")

# Get current carbon footprint
func get_footprint() -> int:
	return carbon_footprint

# Add to carbon footprint
func add_footprint(amount: int):
	var old_footprint = carbon_footprint
	carbon_footprint += amount
	carbon_footprint = max(0, carbon_footprint)
	
	var actual_change = carbon_footprint - old_footprint
	
	if actual_change != 0:
		footprint_changed.emit(actual_change)
		save_footprint_data()
		send_data()  # Send whenever footprint changes
		
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
		send_data()  # Send whenever footprint changes

# Get footprint status
func get_footprint_status() -> String:
	if carbon_footprint < 800:
		return "excellent"
	elif carbon_footprint <= 1200:
		return "average"
	else:
		return "high"

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

# Save footprint data
func save_footprint_data():
	if current_profile == "":
		return
		
	var profile_dir = profiles_folder + current_profile + "/"
	var save_file_path = profile_dir + "carbon_footprint_save.dat"
	
	if not DirAccess.dir_exists_absolute(profile_dir):
		DirAccess.open("user://").make_dir_recursive("profiles/" + current_profile)
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"carbon_footprint": carbon_footprint
		}
		file.store_string(JSON.stringify(save_data))
		file.close()

# Load footprint data
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
			else:
				carbon_footprint = 1000
	else:
		carbon_footprint = 1000

# Reset footprint
func reset_footprint():
	set_footprint(1000)
