extends Node2D

# Variables
var hp: int = 50
@onready var zombie_label = $zombie_label

func update_zombie_label():
	print("Updating label to: ", hp)
	if zombie_label:
		zombie_label.text = str(hp)

func take_damage(amount):
	hp -= amount
	if zombie_label:
		zombie_label.text = str(hp)  # Update the label text
		print("Zombie HP updated to:", hp)
