extends Area2D

@export var soil_type = 2  # Set this in inspector: Pit1=1, Pit2=2, Pit3=3

func _ready():
	monitoring = true
	monitorable = true
	print("Soil area initialized - Type: ", soil_type)

func get_soil_type() -> int:
	return soil_type
