extends Node2D

@onready var combo_label = $"../combo_label"

@onready var trump_attack = $TrumpAttack
@onready var xi_attack = $XiAttack
@onready var kim_attack = $KimAttack
@onready var putin_attack = $PutinAttack

@onready var label_pudding_animation = $"../labelPudding/labelPuddingAnimation"
@onready var label_bomb_animation = $"../labelBomb/labelBombAnimation"
@onready var label_virus_animation = $"../labelVirus/labelVirusAnimation"
@onready var label_fries_animation = $"../labelFries/labelFriesAnimation"

@onready var label_pudding: Label = $"../labelPudding"
@onready var label_fries: Label = $"../labelFries"
@onready var label_bomb: Label = $"../labelBomb"
@onready var label_bodyguard: Label = $"../labelBodyguard"
@onready var label_virus: Label = $"../labelVirus"

@onready var zombie_die = $"../Zombie/zombie_die"
@onready var swapping = $"../swapping"

# Dimensions of the grid in terms of cells
@export var width: int
@export var height: int

# Spacing between grid cells (distance between dots)
@export var offset: int
@export var y_offset: int

# Starting positions of the grid, calculated from the window size.
@onready var x_start = (get_window().size.x - (width * offset) - offset / 2)
@onready var y_start = ((get_window().size.y / 2.0) + ((height / 2.0) * offset) - (offset / 2))

var heroes = []  # List of hero nodes
var zombies: Array = []  # List to store zombies
var hero_damage = {}  # To store attack damage for each hero

@onready var possible_dots = [
	preload("res://Scenes/Dots/blue_dot.tscn"),
	preload("res://Scenes/Dots/green_dot.tscn"),
	preload("res://Scenes/Dots/pink_dot.tscn"),
	preload("res://Scenes/Dots/red_dot.tscn"),
	preload("res://Scenes/Dots/yellow_dot.tscn"),
]

var combo_sounds = [
	preload("res://SFX/combo sound 1.MP3"),
	preload("res://SFX/combo sound 2.MP3"),
	preload("res://SFX/combo sound 3.MP3"),
	preload("res://SFX/combo sound 4.MP3"),
	preload("res://SFX/combo sound 5.MP3"),
]

var combo_count = 0  # Variable to keep track of how many matches are destroyed
var audio_player : AudioStreamPlayer  # Declare an AudioStreamPlayer node

@onready var timer_label = $"../CanvasLayer/Timer_label"

var destroy_timer = Timer.new()
var collapse_timer = Timer.new()
var refill_timer = Timer.new()

var match_timer = Timer.new()

var match_time_limit = 7 # Time limit in seconds
var time_remaining = match_time_limit # Remaining time counter
var match_timer_running = false # To check if the timer is active

var display_score_timer = Timer.new()

var all_dots = []

# Track two dots being swapped by the player
var dot_one = null
var dot_two = null

var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)

# Track the grid positions of the player's initial and final touch during a swipe
var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)

# Tracks if the player is actively interacting.
var controlling = false

# New mechanic
var matches_being_destroyed = false

var sprite_destroyed_count  ={
	"fries" = 0,
	"bomb" = 0,
	"body_guard" = 0,
	"virus" = 0,
	"pudding" = 0
}

func update_sprite_destroyed_count(current_color):
	var color_map = {
		"blue": "pudding",
		"green": "bomb",
		"pink": "fries",
		"red": "virus",
		"yellow": "body_guard"
	}
	if current_color in color_map:
		sprite_destroyed_count[color_map[current_color]] += 1
		# print("%s number is now %d" % [color_map[current_color], sprite_destroyed_count[color_map[current_color]]])

func update_labels():
	# print("Labels updated: ", sprite_destroyed_count)  # Debugging line
	label_fries.text = "%d" %sprite_destroyed_count["fries"]
	label_bomb.text = "%d" %sprite_destroyed_count["bomb"]
	label_bodyguard.text = "%d" %sprite_destroyed_count["body_guard"]
	label_virus.text = "%d" %sprite_destroyed_count["virus"]
	label_pudding.text = "%d" %sprite_destroyed_count["pudding"]
	
	# Update hero damage values dynamically based on labels
	hero_damage["Hero1"] = int(label_pudding.text) if label_pudding.text != "" else 0
	hero_damage["Hero2"] = int(label_bomb.text) if label_bomb.text != "" else 0
	hero_damage["Hero3"] = int(label_virus.text) if label_virus.text != "" else 0
	hero_damage["Hero4"] = int(label_fries.text) if label_fries.text != "" else 0
	
	# Update label text (optional visual update logic)
	print("Hero1 damage: ", hero_damage["Hero1"])
	print("Hero2 damage: ", hero_damage["Hero2"])
	print("Hero3 damage: ", hero_damage["Hero3"])
	print("Hero4 damage: ", hero_damage["Hero4"])

func heroes_attack():
	if zombies.size() == 0:
		print("No zombies to attack!")
		return
	
	var hero_names = ["Hero1", "Hero2", "Hero3", "Hero4"]
	
	# Sequentially attack zombies
	for hero_name in hero_names:
		if zombies.size() > 0:  # Ensure zombie exists before attacking
			await attack_hero(hero_name)
		else:
			print("All zombies are defeated. Stopping attacks.")
			break
	
	reset_labels()
	
	can_touch_input = true  # Restore touch input

# Individual hero attack with animation
func attack_hero(hero_name: String) -> void:
	if hero_name in hero_damage and hero_damage[hero_name] > 0:
		print("%s attacks dealing %d damage" % [hero_name, hero_damage[hero_name]])
		
		# Assuming zombies[0] is the target for simplicity
		if zombies.size() > 0:
			var hero_type = ""
			match hero_name:
				"Hero1":
					hero_type = "pudding"
				"Hero2":
					hero_type = "bomb"
				"Hero3":
					hero_type = "virus"
				"Hero4":
					hero_type = "fries"
			
			# Pass the hero type to the zombie's take_damage function
			zombies[0].take_damage(hero_damage[hero_name], hero_type)
			
			"""var target_zombie = zombies[0]
			target_zombie.take_damage(hero_damage[hero_name])
			
			# Connect to the zombie_destroyed signal
			target_zombie.connect("zombie_destroyed", Callable(self, "_on_zombie_destroyed"))"""
			
		# Play attack animation
		match hero_name:
			"Hero1":
				label_pudding_animation.play("pudding_attack")
			"Hero2":
				label_bomb_animation.play("bomb_attack")
			"Hero3":
				label_virus_animation.play("virus_attack")
			"Hero4":
				label_fries_animation.play("fries_attack")
		
		# Wait until the animation is finished using signal
		await wait_for_animation_to_finish(hero_name)
		
		# Reset animation after it finishes
		match hero_name:
			"Hero1":
				label_pudding_animation.play("RESET")
			"Hero2":
				label_bomb_animation.play("RESET")
			"Hero3":
				label_virus_animation.play("RESET")
			"Hero4":
				label_fries_animation.play("RESET")
		
		#await get_tree().create_timer(0.1).timeout  # Wait 1 second after the attack animation
	else:
		print("%s has no attack damage to deal." % hero_name)
	#await get_tree().create_timer(0.1).timeout

# Function to wait for the animation to finish
func wait_for_animation_to_finish(hero_name: String) -> void:
	match hero_name:
		"Hero1":
			await label_pudding_animation.animation_finished
		"Hero2":
			await label_bomb_animation.animation_finished
		"Hero3":
			await label_virus_animation.animation_finished
		"Hero4":
			await label_fries_animation.animation_finished

# Reset hero labels after attacks
func reset_labels() -> void:
	# Reset the sprite_destroyed_count dictionary
	for key in sprite_destroyed_count.keys():
		sprite_destroyed_count[key] = 0

	# Reset labels
	label_pudding.text = "0"
	label_bomb.text = "0"
	label_virus.text = "0"
	label_fries.text = "0"

	# Reset hero_damage values
	hero_damage["Hero1"] = 0
	hero_damage["Hero2"] = 0
	hero_damage["Hero3"] = 0
	hero_damage["Hero4"] = 0
	
	label_fries.text = "%d" %sprite_destroyed_count["fries"]
	label_bomb.text = "%d" %sprite_destroyed_count["bomb"]
	label_bodyguard.text = "%d" %sprite_destroyed_count["body_guard"]
	label_virus.text = "%d" %sprite_destroyed_count["virus"]
	label_pudding.text = "%d" %sprite_destroyed_count["pudding"]
	
	print("All hero labels and damage value reset.")

# Function to spawn zombies
func spawn_zombie(position: Vector2):
	var zombie_scene = preload("res://Sprites/zombie.tscn")  # Adjust path
	var zombie_instance = zombie_scene.instantiate()
	if zombie_instance:
		print("Zombie spawned with HP: ", zombie_instance)
		add_child(zombie_instance)
		zombie_instance.position = position
		zombies.append(zombie_instance)
		#print("Zombie spawned with HP:", zombie_instance.hp)
		
		# Connect the zombie_destroyed signal to the handler
		zombie_instance.connect("zombie_destroyed", Callable(self, "_on_zombie_destroyed"))
	else:
		print("Zombie instantiation failed.")
	
# Damage the zombie
func damage_zombie(zombie_instance, damage_amount, hero_type):
	print("Trying to damage zombie")
	if zombie_instance:
		print("Zombie instance is valid. Applying damage:", damage_amount)
		zombie_instance.take_damage(damage_amount, hero_type)
	else:
		print("Zombie instance is invalid!")
		
# Handle attack stop for remaining heroes when enemy dies
func _on_zombie_destroyed(zombie_instance):
	if zombie_instance in zombies:
		zombies.erase(zombie_instance)  # Remove the zombie from the list
		print("Zombie destroyed and removed from the list.")


var destroyed_count = 0
var label_display


func _ready() -> void:
	
	setup_timers() # Connects timers to their respective callback functions and sets wait times
	display_score_timer.start()
	randomize()
	all_dots = make_2d_array() # Initializes the all_dots 2D array with null values
	spawn_dots() # Spawns dots into the grid.
	randomize()
	
	# Initialize match timer
	match_timer.connect("timeout", Callable(self, "on_match_timer_timeout"))
	match_timer.set_one_shot(true)
	timer_label.text = ""
	add_child(match_timer)
	
	# Ensure an AudioStreamPlayer node is present
	if not audio_player:
		audio_player = AudioStreamPlayer.new()
		add_child(audio_player)  # Add the player to the scene if not already added
	
	# Spawn enemies
	var zombie1 = spawn_zombie(Vector2(275, 266))
	if zombies.size() > 0:
		damage_zombie(zombies[0], 0, "pudding")
		damage_zombie(zombies[0], 0, "bomb")
		damage_zombie(zombies[0], 0, "virus")
		damage_zombie(zombies[0], 0, "fries")
	
func setup_timers():
	# Manage delays between destroying matches, collapsing columns, and refilling the grid
	destroy_timer.connect("timeout", Callable(self, "destroy_matches"))
	destroy_timer.set_one_shot(true)
	destroy_timer.set_wait_time(0.2)
	add_child(destroy_timer)
	
	collapse_timer.connect("timeout", Callable(self, "collapse_columns"))
	collapse_timer.set_one_shot(true)
	collapse_timer.set_wait_time(0.2)
	add_child(collapse_timer)

	refill_timer.connect("timeout", Callable(self, "refill_columns"))
	refill_timer.set_one_shot(true)
	refill_timer.set_wait_time(0.2)
	add_child(refill_timer)

func start_match_timer():
	time_remaining = match_time_limit
	match_timer.set_wait_time(time_remaining)
	match_timer.start()
	match_timer_running = true
	
func stop_match_timer():
	if match_timer.is_stopped():
		return
	match_timer.stop()
	timer_label.text = ""
	
	display_score_timer.connect("timeout",Callable(self,"display_score"))
	display_score_timer.set_one_shot(true)
	display_score_timer.set_wait_time(1.0)
	add_child(display_score_timer)
	
func is_in_array(array, item):
	for i in array.size():
		if array[i] == item:
			return true
	return false

# Initializes the all_dots 2D array with null values
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func spawn_dots():
	for i in width:
		for j in height:
			# Randomly selects a dot from possible_dots and places it in the grid
			var rand = floor(randf_range(0, possible_dots.size()))
			var dot = possible_dots[rand].instantiate()
			var loops = 0
			# Avoids immediate matches by checking match_at() during dot placement.
			# Checks if placing a dot at (i, j) results in a match (3+ dots of the same color in a row or column)
			while (match_at(i, j, dot.color) && loops < 100):
				rand = floor(randf_range(0,possible_dots.size()))
				loops += 1
				dot = possible_dots[rand].instantiate()
			add_child(dot)
			dot.position = grid_to_pixel(i, j)
			all_dots[i][j] = dot
			
			
func match_at(i, j, color):
	if i > 1:
		if all_dots[i - 1][j] != null && all_dots[i - 2][j] != null:
			if all_dots[i - 1][j].color == color && all_dots[i - 2][j].color == color:
				return true
	if j > 1:
		if all_dots[i][j - 1] != null && all_dots[i][j - 2] != null:
			if all_dots[i][j - 1].color == color && all_dots[i][j - 2].color == color:
				
				return true
	pass

# Convert between grid coordinates and pixel coordinates for dot placement and movement
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start + -offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(pixel_x,pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)

# Checks if a position is within the grid bounds
func is_in_grid(grid_position):
	if grid_position.x >= 0 && grid_position.x < width:
		if grid_position.y >= 0 && grid_position.y < height:
			return true
	return false

var can_touch_input = true  # Controls whether touch input is allowed

func touch_input():
	if Input.is_action_just_pressed("ui_touch") and can_touch_input:
		combo_label.text = ""
		combo_count = 0
		
		# If a touch begins (ui_touch pressed), records the grid position
		var touch_pos = get_global_mouse_position()
		if is_in_grid(pixel_to_grid(touch_pos.x,touch_pos.y)):
			first_touch = pixel_to_grid(touch_pos.x, touch_pos.y)
			dot_one = all_dots[first_touch.x][first_touch.y]
			if dot_one:
				controlling = true
				start_match_timer()
	
	elif Input.is_action_pressed("ui_touch") and controlling:
		# Continuously track touch position
		var current_touch = get_global_mouse_position()
		var current_grid = pixel_to_grid(current_touch.x, current_touch.y)
		if is_in_grid(current_grid) and current_grid != first_touch:
			# If the touch moves to a new grid cell, swap dots
			var direction = current_grid - first_touch
			if abs(direction.x) + abs(direction.y) == 1:  # Ensure only orthogonal swaps
				swap_dots(first_touch.x, first_touch.y, direction)
				first_touch = current_grid  # Update the current grid position
		
	elif Input.is_action_just_released("ui_touch"):
		controlling = false
		stop_match_timer()
		dot_one = null
		dot_two = null
			
func swap_dots(column, row, direction):
	var first_dot = all_dots[column][row]
	var other_dot = all_dots[column + direction.x][row + direction.y]
	
	if first_dot and other_dot:
		# Upgrade grid positions
		all_dots[column][row] = other_dot
		all_dots[column + direction.x][row + direction.y] = first_dot
		
		# Swap positions visually
		first_dot.move(grid_to_pixel(column + direction.x, row + direction.y))
		other_dot.move(grid_to_pixel(column, row))
		swapping.play()
		
func store_info(first_dot, other_dot, place, direciton):
	dot_one = first_dot
	dot_two = other_dot
	last_place = place
	last_direction = direciton
	pass
	
func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_dots(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_dots(grid_1.x, grid_1.y, Vector2(-1, 0))
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_dots(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_dots(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	touch_input()
	
	# Run match detection after the player finishes their turn
	if !controlling:
		find_matches()
	
	if match_timer_running:
		time_remaining -= delta
		if time_remaining > 0 and Input.is_action_pressed("ui_touch"):
			# Update the label text
			timer_label.text = "Time remaining: %d" % int(time_remaining)
		else:
			# Timer expired
			match_timer_running = false
			time_remaining = 0
			timer_label.text = ""
			on_match_timer_timeout()
		
	
func find_matches():
	if matches_being_destroyed:
		return
	
	var found_match = false

	for i in width:
		for j in height:
			if all_dots[i][j] != null:
				var current_color = all_dots[i][j].color
				if i > 0 and i < width -1:
					if !is_piece_null(i - 1, j) and !is_piece_null(i + 1, j):
						if all_dots[i - 1][j].color == current_color and all_dots[i + 1][j].color == current_color:
							match_and_dim(all_dots[i - 1][j])
							match_and_dim(all_dots[i][j])
							match_and_dim(all_dots[i + 1][j])
							found_match = true

				if j > 0 and j < height -1:
					if !is_piece_null(i, j - 1) and !is_piece_null(i, j + 1):
						if all_dots[i][j - 1].color == current_color and all_dots[i][j + 1].color == current_color:
							match_and_dim(all_dots[i][j - 1])
							match_and_dim(all_dots[i][j])
							match_and_dim(all_dots[i][j + 1])
							found_match = true

	if found_match:
		matches_being_destroyed = true # Prevent further matches from being found
		destroy_timer.start()

		destroyed_count = 0 #reset the count to zero

func is_piece_null(column, row):
	if all_dots[column][row] == null:
		return true
	return false

func match_and_dim(item):
	can_touch_input = false  # Disable touch input
	item.matched = true
	item.dim()
	
var color

func destroy_matches():
	can_touch_input = false  # Disable touch input
	var was_matched = false
	destroyed_count = 0
	var total_damage = 0

	var match_delay = 0 # Set the delay between match group destructions (in seconds)
	var matches_to_destroy = []  # Store the matched groups
	var visited = []  # To track visited dots so they are not part of multiple groups

	# Collect all the matched groups
	for i in range(width):
		for j in range(height):
			if all_dots[i][j] != null and all_dots[i][j].matched and not is_visited(i, j, visited):
				var group = get_matched_group(i, j, visited)  # Get the group of matched dots
				if group:
					matches_to_destroy.append(group)
					for dot in group:
						dot.matched = false  # Reset matched status

	if matches_to_destroy.size() > 0:
		was_matched = true

	# Destroy the groups one by one
	var first_match = true  # Flag to track the first match

	for group in matches_to_destroy:
		# Trigger combo count, sound, and label updates immediately
		combo_count += 1
		update_combo_label()
		play_combo_sound(combo_count)
		
		if not first_match:
			pass
		else:
			first_match = false  # After the first match, disable the first match condition

		# Play animations for all dots in the group simultaneously
		for dot in group:
			update_sprite_destroyed_count(dot.color)  # Update count for destroyed color
			
			# Check if the count reaches the threshold of 4 and trigger animations
			var color_map = {
				"blue": "pudding",
				"green": "bomb",
				"pink": "fries",
				"red": "virus",
				"yellow": "body_guard"
			}
			# Trigger special animations under certain requirements
			if dot.color in color_map and sprite_destroyed_count[color_map[dot.color]] >= 4:
				number_of_destroy(dot.color)
			
			# Play animation for the current dot
			var anim_player = dot.get_node_or_null("AnimationPlayer")
			if anim_player:
				anim_player.play("disappear")
		
		update_labels()  # Update any other labels, such as score or time
		
		# Wait for the animation to finish for the entire group
		var max_animation_time = 0.5  # Adjust this to match the duration of your "disappear" animation
		await get_tree().create_timer(max_animation_time).timeout
		# After the animation, queue_free the dot
		for dot in group:
			if dot != null:
				destroyed_count += 1
				dot.queue_free()  # Destroy the dot
		
		# Check if collapse should happen now
		if !matches_being_destroyed:
			collapse_timer.start()  # Make sure the collapse timer is started
			break  # Avoid further operations until collapse is triggered

	# If any matches were destroyed, start the column collapse and refill processes
	if was_matched:
		collapse_columns()  # Start collapsing columns after matches are destroyed
		collapse_timer.start()

	matches_being_destroyed = false

# Function to play combo sound based on combo count
func play_combo_sound(count: int):
	if count <= combo_sounds.size():
		# Set the stream of the player to the corresponding combo sound
		audio_player.stream = combo_sounds[count - 1]
		audio_player.play()  # Play the sound
	else:
		# Play the last sound if the combo count exceeds available sounds
		audio_player.stream = combo_sounds[combo_sounds.size() - 1]
		audio_player.play()

# Function to update the combo label
func update_combo_label():
	combo_label.text = "COMBO %d" % combo_count

# This function gets the matched group of dots starting from the given coordinates
# It also marks the visited dots to ensure that they are not counted in multiple groups
func get_matched_group(x, y, visited):
	var group = []
	if all_dots[x][y] != null and all_dots[x][y].matched and not is_visited(x, y, visited):
		var dot_color = all_dots[x][y].color  # Get the color of the starting dot
		flood_fill_group(x, y, group, visited, dot_color)  # Fill the group with connected dots of the same color
	return group


# This function uses flood fill to collect all the connected matched dots of the same color in the group
# It marks dots as visited so they don't appear in another group
func flood_fill_group(x, y, group, visited, dot_color):
	var stack = [Vector2(x, y)]  # Use Vector2 to store the coordinates
	while stack.size() > 0:
		var pos = stack.pop_back()
		var ix = pos.x
		var iy = pos.y
		if all_dots[ix][iy] != null and all_dots[ix][iy].matched and not is_visited(ix, iy, visited):
			if all_dots[ix][iy].color == dot_color:  # Only add dots of the same color
				group.append(all_dots[ix][iy])
				visited.append(Vector2(ix, iy))  # Mark this dot as visited
				# Check adjacent dots
				if ix + 1 < width and all_dots[ix + 1][iy] != null and all_dots[ix + 1][iy].matched:
					stack.append(Vector2(ix + 1, iy))
				if ix - 1 >= 0 and all_dots[ix - 1][iy] != null and all_dots[ix - 1][iy].matched:
					stack.append(Vector2(ix - 1, iy))
				if iy + 1 < height and all_dots[ix][iy + 1] != null and all_dots[ix][iy + 1].matched:
					stack.append(Vector2(ix, iy + 1))
				if iy - 1 >= 0 and all_dots[ix][iy - 1] != null and all_dots[ix][iy - 1].matched:
					stack.append(Vector2(ix, iy - 1))


# Helper function to check if a dot has already been visited in a group
func is_visited(x, y, visited):
	return visited.has(Vector2(x, y))

					
func collapse_columns():
	can_touch_input = false  # Disable touch input
	await get_tree().create_timer(0.3).timeout
	for i in width:
		for j in height:
			if all_dots[i][j] == null:
				for k in range(j + 1, height):
					if all_dots[i][k] != null:
						all_dots[i][k].move(grid_to_pixel(i, j))
						all_dots[i][j] = all_dots[i][k]
						all_dots[i][k] = null
						break
	refill_timer.start()


func refill_columns():
	can_touch_input = false  # Disable touch input
	for i in width:
		for j in height:
			if all_dots[i][j] == null:
				var rand = floor(randf_range(0, possible_dots.size()))
				var dot = possible_dots[rand].instantiate()
				var loops = 0
				
				while (match_at(i, j, dot.color) && loops < 100): # Prevent infinite loops
					rand = floor(randf_range(0, possible_dots.size()))
					loops += 1
					dot = possible_dots[rand].instantiate()
					
				add_child(dot)
				dot.position = grid_to_pixel(i, j)
				all_dots[i][j] = dot
	after_refill()

# Check if the grid stops collapsing and matching
func after_refill():
	for i in width:
		for j in height:
			if all_dots[i][j] != null:
				if match_at(i, j, all_dots[i][j].color):
					find_matches()
					destroy_timer.start()
					return
	heroes_attack()

func on_match_timer_timeout():
	controlling = false

func number_of_destroy(color):
	print("Destroyed color:", color)
	if color == "blue":
		putin_attack.play_animation_putin()
	
	if color == "green":
		kim_attack.play_animation_kim()
		
	if color == "red" :
		xi_attack.play_animation_xi()
		
	if color == "pink" :
		trump_attack.play_animation_trump()
