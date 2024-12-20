extends Node2D

# Variables
#var hp: int = 30
var pudding_hp: int = 3
var bomb_hp: int = 3
var virus_hp: int = 3
var fries_hp: int = 3

#@onready var zombie_label = $zombie_label
@onready var zombie_label = $zombie_labels
@onready var zombie_animation = $zombie_animation

# Signal to notify when zombie is destroyed
signal zombie_destroyed

func _ready():
	zombie_label.bbcode_enabled = true
	update_zombie_label()	
	# Connect the animation_finished signal
	if zombie_animation:
		zombie_animation.animation_finished.connect(_on_animation_finished)

func update_zombie_label():
	#print("Updating label to: ", hp)
	if zombie_label:
		print("zombie label text")
		#zombie_label.text = str(hp)
		zombie_label.bbcode_text = """
		[img=50]res://Sprites/Pudding.png \n"""
		#[img=50]res://Sprites/virus.png
		#[img=50x50]res://Sprites/Nuclear bomb.png
		#[img=50x50]res://Sprites/virus.png
		#[img=50x50]res://Sprites/Mcdonald.png
		
		#""" #% [pudding_hp, bomb_hp, virus_hp, fries_hp]"""

func take_damage(amount, hero_type):
	if amount > 0:
		match hero_type:
			"pudding":
				pudding_hp -= max(pudding_hp - amount, 0)
			"bomb":
				bomb_hp -= max(bomb_hp - amount, 0)
			"virus":
				virus_hp -= max(virus_hp - amount, 0)
			"fries":
				fries_hp -= max(fries_hp - amount, 0)
				
		update_zombie_label()

		# Check if all HP types are 0 to trigger death animation
		if pudding_hp == 0 and bomb_hp == 0 and virus_hp == 0 and fries_hp == 0:
		   # All HPs depleted; start death sequence
			zombie_label.hide()
			zombie_animation.play("death")
		else:
			zombie_animation.play("attacked")
		
		"""hp -= amount
		if hp <= 0:
			# Hide the label immediately when the zombie starts its "death" animation
			zombie_label.hide()
			emit_signal("zombie_destroyed", self) # Notify to other heroes
			zombie_animation.play("death")
		else:
			zombie_animation.play("attacked")
	if zombie_label:
		zombie_label.text = str(hp)  # Update the label text
			#print("Zombie HP updated to:", hp)"""

func _on_animation_finished(anim_name):
	if anim_name == "death":
		print("Zombie has died. Removing from scene.")
		# Remove both the zombie and its label
		"""if zombie_label:
			zombie_label.queue_free()"""
		emit_signal("zombie_destroyed", self)  # Ensure signal is emitted
		queue_free()
