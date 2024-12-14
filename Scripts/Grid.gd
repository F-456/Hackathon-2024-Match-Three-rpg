extends Node2D

# Determines the game state (wait or move)
enum {wait, move}
var state

# Dimensions of the grid in terms of cells
@export var width: int
@export var height: int

# Spacing between grid cells (distance between dots)
@export var offset: int
@export var y_offset: int

# Starting positions of the grid, calculated from the window size.
@onready var x_start = ((get_window().size.x / 2.0) - ((width/2.0) * offset ) + (offset / 2))
@onready var y_start = ((get_window().size.y / 2.0) + ((height/2.0) * offset ) - (offset / 2))

#@export var empty_spaces: PackedVector2Array

@onready var possible_dots = [
	preload("res://Scenes/Dots/blue_dot.tscn"),
	preload("res://Scenes/Dots/green_dot.tscn"),
	preload("res://Scenes/Dots/pink_dot.tscn"),
	preload("res://Scenes/Dots/red_dot.tscn"),
	preload("res://Scenes/Dots/yellow_dot.tscn"),
]

var destroy_timer = Timer.new()
var collapse_timer = Timer.new()
var refill_timer = Timer.new()

var all_dots = []

# Track two dots being swapped by the player
var dot_one = null
var dot_two = null

var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false

# Track the grid positions of the player's initial and final touch during a swipe
var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)

# Tracks if the player is actively interacting.
var controlling = false


var sprite_destroyed_count  ={
	"fries" = 0,
	"bomb" = 0,
	"body_guard" = 0,
	"virus" = 0,
	"pudding" = 0,
	
}

func _ready():
	state = move
	setup_timers() # Connects timers to their respective callback functions and sets wait times
	randomize() 
	all_dots = make_2d_array() # Initializes the all_dots 2D array with null values
	spawn_dots() # Spawns dots into the grid.
	
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

func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		# If a touch begins (ui_touch pressed), records the grid position
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x,get_global_mouse_position().y)):
			first_touch = pixel_to_grid(get_global_mouse_position().x,get_global_mouse_position().y)
			controlling = true
	if Input.is_action_just_released("ui_touch"):
		# If a touch ends (ui_touch released), calculates the swipe direction and swaps dots
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x,get_global_mouse_position().y)) && controlling:
			controlling = false
			final_touch = pixel_to_grid(get_global_mouse_position().x,get_global_mouse_position().y )
			touch_difference(first_touch, final_touch)
			
func swap_dots(column, row, direction):
	var first_dot = all_dots[column][row]
	var other_dot = all_dots[column + direction.x][row + direction.y]
	if first_dot != null && other_dot != null:
		store_info(first_dot, other_dot, Vector2(column, row), direction)
		state = wait
		all_dots[column][row] = other_dot
		all_dots[column + direction.x][row + direction.y] = first_dot
		first_dot.move(grid_to_pixel(column + direction.x, row + direction.y))
		other_dot.move(grid_to_pixel(column, row))
		if !move_checked:
			find_matches()
		
func store_info(first_dot, other_dot, place, direciton):
	dot_one = first_dot
	dot_two = other_dot
	last_place = place
	last_direction = direciton
	pass
		
func swap_back():
	if dot_one != null && dot_two != null:
		swap_dots(last_place.x, last_place.y, last_direction)
	state = move
	move_checked = false
	
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

func _process(_delta):
	if state == move:
		touch_input()
	
func find_matches():
	for i in width:
		for j in height:
			if all_dots[i][j] != null:
				var current_color = all_dots[i][j].color
				if i > 0 && i < width -1:
					if !is_piece_null(i - 1, j) && !is_piece_null(i + 1, j):
						if all_dots[i - 1][j].color == current_color && all_dots[i + 1][j].color == current_color:
							match_and_dim(all_dots[i - 1][j])
							match_and_dim(all_dots[i][j])
							match_and_dim(all_dots[i + 1][j])
							
							#detect current color to add value to the dictionary
							if current_color == "blue":
								sprite_destroyed_count["pudding"] += 1
								print ("pudding number is now %d" % sprite_destroyed_count["pudding"])
							if current_color == "green":
								sprite_destroyed_count["bomb"] += 1
								print ("bomb number is now %d" % sprite_destroyed_count["bomb"])
							if current_color == "pink":
								sprite_destroyed_count["fries"] += 1
								print ("fries number is now %d" % sprite_destroyed_count["fries"])
							if current_color == "red":
								sprite_destroyed_count["virus"] += 1
								print ("virus number is now %d" % sprite_destroyed_count["virus"])
							if current_color == "yellow":
								sprite_destroyed_count["body_guard"] += 1
								print ("body guard number is now %d" % sprite_destroyed_count["body_guard"])
								
								
							
				if j > 0 && j < height -1:
					if !is_piece_null(i, j - 1) && !is_piece_null(i, j + 1):
						if all_dots[i][j - 1].color == current_color && all_dots[i][j + 1].color == current_color:
							match_and_dim(all_dots[i][j - 1])
							match_and_dim(all_dots[i][j])
							match_and_dim(all_dots[i][j + 1])
							if current_color == "blue":
								sprite_destroyed_count["pudding"] += 1
								print ("pudding number is now %d" % sprite_destroyed_count["pudding"])
							if current_color == "green":
								sprite_destroyed_count["bomb"] += 1
								print ("bomb number is now %d" % sprite_destroyed_count["bomb"])
							if current_color == "pink":
								sprite_destroyed_count["fries"] += 1
								print ("fries number is now %d" % sprite_destroyed_count["fries"])
							if current_color == "red":
								sprite_destroyed_count["virus"] += 1
								print ("virus number is now %d" % sprite_destroyed_count["virus"])
							if current_color == "yellow":
								sprite_destroyed_count["body_guard"] += 1
								print ("body guard number is now %d" % sprite_destroyed_count["body_guard"])
								
	destroy_timer.start()

func is_piece_null(column, row):
	if all_dots[column][row] == null:
		return true
	return false

func match_and_dim(item):
	item.matched = true
	item.dim()

func destroy_matches():
	var was_matched = false
	for i in width:
		for j in height:
			if all_dots[i][j] != null:
				if all_dots[i][j].matched:
					was_matched = true
					all_dots[i][j].queue_free()
					all_dots[i][j] = null
	move_checked = true
	if was_matched:
		collapse_timer.start()
	else:
		swap_back()
					
func collapse_columns():
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
	for i in width:
		for j in height:
			if all_dots[i][j] == null:
				var rand = floor(randf_range(0, possible_dots.size()))
				var dot = possible_dots[rand].instantiate()
				var loops = 0
				while (match_at(i, j, dot.color) && loops < 100):
					rand = floor(randf_range(0,possible_dots.size()))
					loops += 1
					dot = possible_dots[rand].instantiate()
				add_child(dot)
				dot.position = grid_to_pixel(i, j - y_offset)
				dot.move(grid_to_pixel(i,j))
				all_dots[i][j] = dot
	after_refill()
				
func after_refill():
	for i in width:
		for j in height:
			if all_dots[i][j] != null:
				if match_at(i, j, all_dots[i][j].color):
					find_matches()
					destroy_timer.start()
					return
	state = move
	move_checked = false
