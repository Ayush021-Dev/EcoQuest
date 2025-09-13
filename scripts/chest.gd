extends Node2D

@export var coins_amount: int = 10
var player_in_range: bool = false
var player_ref = null
var is_opened: bool = false  # Added flag to track if this chest is opened

@onready var animated_sprite := $AnimatedSprite2D
@onready var area := $AnimatedSprite2D/Area2D
@onready var prompt_label := $PromptLabel  # Adjust or remove if not used

func _ready():
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	else:
		push_error("Area2D node not found!")
	if animated_sprite:
		animated_sprite.play("idle")
	if prompt_label:
		prompt_label.visible = false

func _on_body_entered(body):
	if body.is_in_group("Player") and not is_opened:
		player_in_range = true
		player_ref = body
		if animated_sprite:
			animated_sprite.play("found")
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		player_ref = null
		if not is_opened and animated_sprite:
			animated_sprite.play("idle")
		if prompt_label:
			prompt_label.visible = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact") and not is_opened:
		give_coins()

func give_coins():
	if player_ref and "coins" in player_ref and not is_opened:
		player_ref.coins += coins_amount
		if animated_sprite:
			animated_sprite.play("opened")
		if prompt_label:
			prompt_label.visible = false  # Hide prompt after opening
		print("Player received", coins_amount, "coins")
		is_opened = true
		area.set_deferred("monitoring", false)
	elif player_ref:
		print("Player has no 'coins' property")
