extends Node

signal avatar_changed(new_index)
signal coins_changed(coin_difference)  # Changed to pass difference instead of total

var avatars = [
	{"name": "Default", "sprite_frames_path": "res://avatars/default.tres", "unlocked": true, "price": 0},
	{"name": "Avatar 2", "sprite_frames_path": "res://avatars/avatar2.tres", "unlocked": false, "price": 50},
	{"name": "Avatar 3", "sprite_frames_path": "res://avatars/avatar3.tres", "unlocked": false, "price": 100},
	{"name": "Avatar 4", "sprite_frames_path": "res://avatars/avatar4.tres", "unlocked": false, "price": 150},
	{"name": "Avatar 5", "sprite_frames_path": "res://avatars/avatar5.tres", "unlocked": false, "price": 200},
	{"name": "Miss Earth", "sprite_frames_path": "res://avatars/missearth.tres", "unlocked": false, "price": 300}
]
@onready var select_unlock_sound = $PauseCanvas/AvatarSelectionPanel/SelectButton/UnlockSound
var current_avatar_index = 0
var total_coins: int = 0  # Global coin storage

func _ready():
	# Initialize with some starting coins for testing
	total_coins = 50

# Coin management functions
func get_coins() -> int:
	return total_coins

func add_coins(amount: int):
	total_coins += amount
	emit_signal("coins_changed", amount)  # Emit the amount added, not the total
	print("Added ", amount, " coins. Total: ", total_coins)

func spend_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		emit_signal("coins_changed", -amount)  # Emit negative amount for spending
		print("Spent ", amount, " coins. Total: ", total_coins)
		return true
	return false

# Avatar management functions
func get_current_avatar():
	return avatars[current_avatar_index]

func unlock_avatar(index):
	if index < avatars.size():
		avatars[index]["unlocked"] = true
		print("Unlocked: ", avatars[index]["name"])

func buy_avatar(index) -> bool:
	if index < avatars.size():
		var avatar = avatars[index]
		if not avatar["unlocked"] and spend_coins(avatar["price"]):
			unlock_avatar(index)
			select_unlock_sound.play()
			return true
	return false

func change_avatar(index):
	if index < avatars.size() and avatars[index]["unlocked"]:
		current_avatar_index = index
		emit_signal("avatar_changed", index)
		print("Changed to: ", avatars[index]["name"])
		return true
	return false

func get_avatar(index):
	if index < avatars.size():
		return avatars[index]
	return null

func get_avatar_count():
	return avatars.size()
