extends Node2D

var bombs_required = 5  # Initial bombs required to defeat the zombie
var bombs_matched = 0  # Track the bombs matched
var bombs_label: Label  # Reference to the label displaying bomb count

# Called when the node enters the scene tree for the first time
func _ready():
	# Get the reference to the label (assuming it's a child node of the zombie)
	bombs_label = $bombs_label
	
	if bombs_label == null:
		print("BombsLabel is not found!")
		return
	
	# Initialize the label text to display the number of bombs required
	bombs_label.text = str(bombs_required)
	print("Label initialized with text: ", bombs_label.text)

# Function to call when a bomb is matched
func on_bomb_matched():
	if bombs_matched < bombs_required:
		bombs_matched += 1
		bombs_label.text = str(bombs_required - bombs_matched)
		print("Bombs matched: ", bombs_matched, " Remaining: ", bombs_label.text)

		# Check if the zombie is defeated
		if bombs_matched >= bombs_required:
			defeat_zombie()

# Function to handle the defeat of the zombie
func defeat_zombie():
	print("Zombie defeated!")
	queue_free()  # Remove the zombie from the scene (or implement other defeat logic)
