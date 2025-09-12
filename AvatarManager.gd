extends Node

signal avatar_changed(new_index)

var avatars = [
	{"name": "Default", "sprite_frames_path": "res://avatars/default.tres", "unlocked": true},
	{"name": "Avatar 2", "sprite_frames_path": "res://avatars/avatar2.tres", "unlocked": true},
	{"name": "Avatar 3", "sprite_frames_path": "res://avatars/avatar3.tres", "unlocked": false},
	{"name": "Avatar 4", "sprite_frames_path": "res://avatars/avatar4.tres", "unlocked": false},
	{"name": "Avatar 5", "sprite_frames_path": "res://avatars/avatar5.tres", "unlocked": false},
	{"name": "Miss Earth", "sprite_frames_path": "res://avatars/missearth.tres", "unlocked": true}
]

var current_avatar_index = 0

func get_current_avatar():
	return avatars[current_avatar_index]

func unlock_avatar(index):
	if index < avatars.size():
		avatars[index]["unlocked"] = true
		print("Unlocked: ", avatars[index]["name"])

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
