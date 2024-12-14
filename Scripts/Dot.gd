extends Node2D

# This exported variable stores the color of the dot.
@export var color = ""
@onready var sprite = get_node("Sprite2D")
var matched = false

func _ready():
	pass
	
func move(target):
	var tween = get_tree().create_tween()
	tween.tween_property(self, 'position', target, 0.2)

func dim():
	sprite.modulate = Color(1, 1, 1, 0.5)
