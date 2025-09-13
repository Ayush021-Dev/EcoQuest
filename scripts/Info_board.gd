extends Node2D

@export var quotes := [
	"Did you know Earth is hotter now than anytime in the last 125000 years",
	"Cows are like walking chimneys because their burps trap a lot of heat",
	"Melting ocean ice is like ice cubes in your drink no water level rise but land ice is different",
	"Plant one tree and it cleans as much air as two days of car pollution",
	"Plastic bottles never really disappear they just turn into tiny invisible dust",
	"Humans release way more CO2 than volcanoes every year about 100 times more",
	"Coral reefs are like underwater cities lose them and so do a quarter of ocean creatures",
	"The ocean soaks up lots of extra heat like a giant earth sized sponge",
	"Polar bears can swim super far but they really need ice to rest on",
	"Flying from London to New York melts about 3 square meters of Arctic ice oops",
	"Cities act like giant frying pans storing heat in all their concrete",
	"Frozen ground in the Arctic is like a giant freezer for carbon if it melts that door swings wide open",
	"Switch all your lights to LED and its like taking 100 million cars off the road",
	"Ozone hole and climate change are not the same think sunburn versus a fever",
	"The Great Pacific Garbage Patch is so big it could fit two Indias inside it",
	"Climate change is a double challenge droughts here floods there",
	"Making just one T shirt uses enough water for someone to drink for three years",
	"The Amazon cleans our air but cutting it down just makes things worse",
	"One out of every three bites of your food is thanks to busy bees",
	"Rising seas might make millions of people climate nomads by 2050",
	"Earths temperature has risen about 12 degrees Celsius kinda like a fever",
	"If all the ice melted sea levels would rise about 70 meters as tall as a skyscraper",
	"Wind and solar power are now cheaper than coal sweet cheat codes",
	"The Sahara was once a grassy land with hippos and giraffes",
	"Cars buses and planes produce one quarter of all human CO2 emissions",
	"Ocean acid is like soda for the sea it is bad news for shells and coral",
	"The hottest temperature on Earth was 567 degrees thats like living inside an oven",
	"Mosquitoes are leveling up spreading diseases further thanks to warmer air",
	"Only 9 percent of all plastic ever made has been recycled yikes",
	"Mangroves are superhero trees that stop storms and trap tons of carbon",
	"Greenlands ice could flood coastlines by 7 meters if it all melts",
	"Fashion causes more CO2 emissions than all planes and ships combined",
	"Krill tiny shrimp are ocean heroes that bury lots of carbon deep down",
	"Heatwaves happen five times more often now like an unfair respawn in a game",
	"Eating less beef helps save forests and cut down greenhouse gases",
	"Bamboo grows crazy fast up to 35 inches in one day",
	"By 2050 there might be more plastic than fish in the ocean by weight",
	"Sea level rise isnt even everywhere some spots sink faster than others",
	"Some offshore wind turbines are taller than the Eiffel Tower crazy big",
	"Wasting less energy is the easiest and cheapest upgrade for our planet"
]

var player_in_range: bool = false
var player_ref = null
var quote_visible := false  # Tracks if popup is visible
@onready var area := $Area2D
@onready var prompt_label := $Label  # your prompt label node
@onready var quote_popup := $QuotePopup  # your popup panel node
@onready var quote_label := $QuotePopup/QuoteLabel  # label inside popup
@onready var close_button := $QuotePopup/CloseButton  # close button inside popup
@onready var close_click_sound := $QuotePopup/CloseButton/CloseClickSound  # optional sound
@onready var animation_player := $AnimatedSprite2D

func _ready():
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	if prompt_label:
		prompt_label.visible = false
	if quote_popup:
		quote_popup.visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if animation_player:
		animation_player.play("idle")

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		player_ref = body
		if animation_player:
			animation_player.play("found")
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		player_ref = null
		if prompt_label:
			prompt_label.visible = false
		hide_quote()

func _process(_delta):
	# Keep quote_popup centered on current viewport if visible
	if quote_visible and quote_popup:
		center_popup_on_viewport()

	if player_in_range and Input.is_action_just_pressed("interact"):
		if quote_visible:
			hide_quote()
		else:
			show_random_quote()

func center_popup_on_viewport():
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Get the viewport size
		var viewport_size = get_viewport().get_visible_rect().size
		# Get camera's global position
		var camera_pos = camera.global_position
		# Calculate the top-left corner of the visible area
		var viewport_top_left = camera_pos - viewport_size * 0.5
		# Center the popup in the visible area
		var popup_size = quote_popup.size
		quote_popup.global_position = viewport_top_left + (viewport_size - popup_size) * 0.5
	else:
		# Fallback: center on screen if no camera found
		var screen_size = get_viewport().get_visible_rect().size
		var popup_size = quote_popup.size
		quote_popup.position = (screen_size - popup_size) * 0.5

func show_random_quote():
	if quote_popup and quote_label:
		var idx = randi() % quotes.size()
		quote_label.text = quotes[idx]
		
		# Center the popup on viewport
		center_popup_on_viewport()
		
		quote_popup.visible = true
		quote_visible = true
		
		# Disable player movement while quote is visible
		if player_ref and player_ref.has_method("set_movement_enabled"):
			player_ref.set_movement_enabled(false)

func hide_quote():
	if quote_popup:
		quote_popup.visible = false
		quote_visible = false
		# Enable player movement when quote hidden
		if player_ref and player_ref.has_method("set_movement_enabled"):
			player_ref.set_movement_enabled(true)
		if animation_player:
			animation_player.play("idle")

func _on_close_pressed():
	if close_click_sound:
		close_click_sound.play()
	hide_quote()
