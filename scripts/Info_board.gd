extends Node2D

@export var quotes := [
"Did you know Earth's atmosphere is thickening like a blanket that's trapping too much heat",
"Bristlecone pines are some of the oldest living organisms, over 4600 years old",
"More than half of all life on Earth lives underground hidden from sight",
"Koalas get nearly all their moisture from eucalyptus leaves, rarely drinking water",
"Dolphins use signature whistles like names to recognize each other",
"Some mushrooms can clean up oil spills and absorb radiation from the ground",
"It takes more energy to make 1 kg of paper than 1 kg of steel",
"Sea turtles' egg gender depends on how warm the sand is during incubation",
"96.5% of Earth's water is in the oceans, the rest mostly locked in ice",
"Dragonflies have been flying around for over 300 million years, outlasting dinosaurs",
"Supermarkets use about 60 million paper bags each year, stacking into mountains",
"Ants on Earth outweigh all humans combined, with over 100 trillion ants alive",
"The open ocean is the largest ecosystem on Earth full of mysterious creatures",
"78% of marine mammals risk choking on plastic waste every year",
"Fungi connect plants underground like a hidden natural internet",
"Recycling a newspaper could save up to 75,000 trees",
"Temperate rainforests grow in Scotland and Chile, not just tropical zones",
"Orangutans are losing rainforest homes in Indonesia to logging and fires",
"The glass bottle thrown last week could last a million years in a landfill",
"Only 1% of Earth's water is usable for drinking and farming",
"The US throws away 25 trillion Styrofoam cups each year lasting centuries",
"Insects are essential pollinators without them we'd miss most of our food",
"One mile of US highway reveals over 1,400 pieces of litter on average",
"Recycling a glass bottle powers a light bulb for about four hours",
"Bamboo is grass, not tree, and regrows incredibly fast",
"Sea levels rose 23 cm since 1880, more than a school ruler",
"African buffalo herds vote to make group decisions",
"The world's oldest tree is a 5,000-year-old pine in California",
"Sharks existed before trees and survived all mass extinctions",
"Greenhouse gases are natural, but too much overheats Earth",
"Unpredictable rain makes tea a rare treat in some countries",
"Coral reefs support a quarter of all marine life but are threatened by warming",
"The Sahara was once lush grassland with lakes and wildlife",
"Trees 'talk' through scents warning of hungry bugs",
"US throws away enough aluminum every 3 months to rebuild its air fleet",
"Mangroves act as wave barriers protecting coasts from storms",
"A glass bottle can outlast human civilization if left unburied",
"The telescopefish has tubular, binocular-like eyes to spot prey above",
"Prow Knob, a new island, emerged in Alaska due to glacier retreat",
"Gravitational waves were detected in 2015, confirming Einstein's prediction",
"Scientists discovered highly alkaline barrels off Los Angeles coast",
"A cloud weighs around a million tonnes",
"Giraffes are 30 times more likely to get hit by lightning than humans",
"Humans use only 1% of all available water",
"Rainforests are being cut down at the rate of 100 acres per minute",
"The US is the #1 trash-producing country in the world",
"More than 20 million Hershey's Kisses are wrapped each day",
"It takes almost 500,000 litres of water to extract just 1 kg of gold",
"Only 0.5% of water on Earth is usable and available freshwater",
"In the last 500 years, human activity is known to have forced 869 species to extinction",
"The Great Pacific Garbage Patch is a massive collection of marine debris",
"Moths in the family Saturniidae have no mouths and don't eat as adults",
"The ratio of human cells to bacteria cells in your body is roughly 1:1",
"Mitochondria and chloroplasts were most likely ancient bacteria engulfed by cells",
"The human stomach can dissolve razor blades",
"A laser can get trapped in water",
"Earth's oceans contain 99% of the planet's living space",
"The Amazon rainforest produces 20% of the world's oxygen",
"A single tree can absorb carbon dioxide at a rate of 48 pounds per year",
"The fastest-growing plant is bamboo, which can grow up to 35 inches in a single day",
"The world's largest desert is not the Sahara, but Antarctica",
"The Eiffel Tower can be 15 cm taller during the summer due to thermal expansion",
"Honey never spoils; archaeologists have found pots of honey in ancient tombs",
"A day on Venus is longer than a year on Venus",
"Octopuses have three hearts and blue blood",
"Bananas are berries, but strawberries aren't",
"The Eiffel Tower can be 15 cm taller during the summer due to thermal expansion",
"The shortest war in history lasted 38 to 45 minutes",
"The longest hiccuping spree lasted 68 years",
"The human nose can detect over 1 trillion different scents",
"The shortest commercial flight in the world lasts just 57 seconds",
"The longest hiccuping spree lasted 68 years",
"A group of flamingos is called a 'flamboyance'",
"The world's largest snowflake on record was 15 inches wide and 8 inches thick",
"The world's largest desert is not the Sahara, but Antarctica",
"The Eiffel Tower can be 15 cm taller during the summer due to thermal expansion",
"Honey never spoils; archaeologists have found pots of honey in ancient tombs"
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
