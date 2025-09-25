extends Node
# Carbon Footprint Manager - Singleton for tracking global carbon footprint score
# Lower scores are better (like golf scoring)

signal footprint_changed(footprint_difference: int)

var carbon_footprint: int = 1000  # Starting footprint score
var save_file_path: String = "user://carbon_footprint_save.dat"

# Simple HTTP test variables
var http_request: HTTPRequest

func _ready():
	load_footprint_data()
	setup_http()
	# Send data when game starts
	send_data()

# Setup HTTP request for testing
func setup_http():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# Send data function - called automatically
func send_data():
	var data = {
		"student_name": "TestStudent",
		"carbon_footprint": carbon_footprint,
		"status": get_footprint_status(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var url = "https://webhook.site/832a2e5b-9f94-473c-8b48-a9880ddb3882"  # Replace with your webhook URL
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
	print("Response: ", response_text)
	
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

# Save footprint data
func save_footprint_data():
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"carbon_footprint": carbon_footprint
		}
		file.store_string(JSON.stringify(save_data))
		file.close()

# Load footprint data
func load_footprint_data():
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
				print("Error parsing carbon footprint save file")
				carbon_footprint = 1000
	else:
		carbon_footprint = 1000

# Reset footprint to default (for testing or new game)
func reset_footprint():
	set_footprint(1000)
