extends Node2D

# Variables
var hp: int = 1
@onready var zombie_label = $zombie_label
@onready var zombie_animation = $zombie_animation

# Signal to notify when zombie is destroyed
signal zombie_destroyed

func _ready():
	# Connect the animation_finished signal
	if zombie_animation:
		zombie_animation.animation_finished.connect(_on_animation_finished)

func update_zombie_label():
	#print("Updating label to: ", hp)
	if zombie_label:
		zombie_label.text = str(hp)

func take_damage(amount):
	if amount > 0:
		hp -= amount
		if hp <= 0:
			# Hide the label immediately when the zombie starts its "death" animation
			zombie_label.hide()
			emit_signal("zombie_destroyed", self) # Notify to other heroes
			zombie_animation.play("death")
		else:
			zombie_animation.play("attacked")
	if zombie_label:
			zombie_label.text = str(hp)  # Update the label text
			#print("Zombie HP updated to:", hp)

func _on_animation_finished(anim_name):
	if anim_name == "death":
		print("Zombie has died. Removing from scene.")
		# Remove both the zombie and its label
		if zombie_label:
			zombie_label.queue_free()
		emit_signal("zombie_destroyed", self)  # Ensure signal is emitted
		queue_free()
