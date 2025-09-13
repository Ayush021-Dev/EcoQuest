extends Node2D

@export var quotes := [
	"Adventure awaits in every corner.",
	"Knowledge is the greatest treasure.",
	"Beware, for monsters roam at night.",
	"Rest restores courage and strength.",
	"Courage and kindness open every door."
]

var player_in_range: bool = false
var player_ref = null

@onready var area := $Area2D
@onready var prompt_label := $Label  # matches your prompt label node
@onready var quote_popup := $QuotePopup  # your Panel node for the popup
@onready var quote_label := $QuotePopup/QuoteLabel  # the Label node INSIDE the popup
@onready var close_button := $QuotePopup/CloseButton  # the Close button inside QuotePopup
@onready var close_click_sound := $QuotePopup/CloseButton/CloseClickSound  # adjust the path if different

func _ready():
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	if prompt_label:
		prompt_label.visible = false
	if quote_popup:
		quote_popup.visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)  # Connect button pressed signal

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		player_ref = body
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		player_ref = null
		if prompt_label:
			prompt_label.visible = false
		if quote_popup:
			quote_popup.visible = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		show_random_quote()

func show_random_quote():
	if quote_popup and quote_label:
		var idx = randi() % quotes.size()
		quote_label.text = quotes[idx]
		quote_popup.visible = true

func _on_close_pressed():
	if close_click_sound:
		close_click_sound.play()
	if quote_popup:
		quote_popup.visible = false
