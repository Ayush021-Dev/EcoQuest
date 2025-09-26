extends CharacterBody2D

@export var dialogues := [
	"Hi young fella, I am the guardian of this forest.",
	"This area was once a lush forest with plenty of life.",
	"But deforestation has taken its toll, harming the environment.",
	"You must play the games ahead to restore balance and regrow trees.",
	"Good luck! The future of this forest depends on you."
]

var player_in_range: bool = false
var player_ref = null
var dialogue_index: int = 0
var dialogue_active: bool = false
var typing = false
var level_completed: bool = false

@onready var area := $Area2D
@onready var prompt_label := $TalkPrompt
@onready var dialogue_box := $TextureRect
@onready var dialogue_label := $TextureRect/Label
@onready var animated_sprite := $AnimatedSprite2D
@export var coin_scene = preload("res://scenes/Coin.tscn")  # Adjust path as needed

# New dialogues after completion
var celebration_dialogues := [
	"Bravo! Your brilliance and wisdom have restored the forest.",
	"Your love for trees is inspiring.",
	"Here, take some eco-coins as a reward."
]

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	prompt_label.visible = false
	dialogue_box.visible = false
	animated_sprite.animation = "old_man idle"
	animated_sprite.play()

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		player_ref = body
		prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		player_ref = null
		prompt_label.visible = false
		if dialogue_active:
			end_dialogue()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		if not dialogue_active:
			start_dialogue()
		elif not typing:
			advance_dialogue()

func start_dialogue():
	dialogue_active = true
	dialogue_index = 0
	prompt_label.visible = false
	dialogue_box.visible = true
	animated_sprite.animation = "old_man talk"
	animated_sprite.play()
	_start_typing(get_current_dialogues()[dialogue_index])
	if player_ref and player_ref.has_method("set_movement_enabled"):
		player_ref.set_movement_enabled(false)

func advance_dialogue():
	dialogue_index += 1
	var d = get_current_dialogues()
	if dialogue_index < d.size():
		_start_typing(d[dialogue_index])
	else:
		end_dialogue()
		# If celebration dialogues just ended, spawn coin
		if level_completed:
			give_eco_coins()

func end_dialogue():
	dialogue_active = false
	dialogue_box.visible = false
	prompt_label.visible = true
	animated_sprite.animation = "old_man idle"
	animated_sprite.play()
	if player_ref and player_ref.has_method("set_movement_enabled"):
		player_ref.set_movement_enabled(true)

func _start_typing(text):
	typing = true
	dialogue_label.text = ""
	_type_text(text)

func _type_text(text) -> void:
	for c in text:
		dialogue_label.text += c
		await get_tree().create_timer(0.05).timeout
	typing = false

func get_current_dialogues() -> Array:
	if level_completed:
		return celebration_dialogues
	return dialogues

# This function moves the old man to the new position and switches to celebration state
func celebrate_completion():
	level_completed = true
	position = Vector2(218.0, 386.0)
	prompt_label.visible = true
	dialogue_active = false
	dialogue_index = 0
	dialogue_box.visible = false
	animated_sprite.animation = "old_man idle"
	animated_sprite.play()

# Spawn the eco coin just above the old man
func give_eco_coins():
	var coin = coin_scene.instance()
	coin.position = position + Vector2(0, -40)  # 40 pixels above
	get_parent().add_child(coin)
