extends CharacterBody2D

@export var dialogues := [
	"Hello, traveler. I'm the fisherman of this lake.",
	"The lake was my livelihood, full of fish and life.",
	"Now pollution has choked its waters, leaving it lifeless.",
	"We need to clean this lake and restore its beauty.",
	"Can you help by completing the tasks ahead?",
	"Together, we can bring the fish back and heal the lake."
]

var player_in_range: bool = false
var player_ref = null
var dialogue_index: int = 0
var dialogue_active: bool = false
var typing = false

@onready var area := $Area2D
@onready var prompt_label := $TalkPrompt
@onready var dialogue_box := $TextureRect
@onready var dialogue_label := $TextureRect/Label
@onready var animated_sprite := $AnimatedSprite2D

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	prompt_label.visible = false
	dialogue_box.visible = false
	animated_sprite.animation = "fisherman_idle"
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
	animated_sprite.animation = "fisherman_talk"
	animated_sprite.play()
	_start_typing(dialogues[dialogue_index])

	if player_ref and player_ref.has_method("set_movement_enabled"):
		player_ref.set_movement_enabled(false)

func advance_dialogue():
	dialogue_index += 1
	if dialogue_index < dialogues.size():
		_start_typing(dialogues[dialogue_index])
	else:
		end_dialogue()

func end_dialogue():
	dialogue_active = false
	dialogue_box.visible = false
	prompt_label.visible = true
	animated_sprite.animation = "fisherman_idle"
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
