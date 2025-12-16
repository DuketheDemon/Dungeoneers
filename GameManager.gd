extends Node2D 

# --- SCRIPT VARIABLES (Link these in the 2D editor Inspector) ---
@export var output_label: RichTextLabel
@export var input_field: LineEdit

# --- GLOBAL GAME STATE VARIABLES ---
var items: Array = [] 
var current_room_name: String = "" # Store the name string, not the dict
var world_rooms: Dictionary = {} 
var game_running: bool = true # New variable to control the game loop

# --- ROOM CONSTANTS ---
const START = 1
const FORK = 2
const BLUE = 3
const ORANGE = 4
const MONSTER = 5
const WIN = 6

# ================================================================
#                       CORE GODOT FUNCTIONS
# ================================================================

func _ready():
	# Runs when the game starts
	disclaimer()
	build_world()
	start_new_game()
	input_field.grab_focus() 

# This function runs every time the user hits ENTER in the UI
func _on_input_field_text_submitted(user_input):
	if not game_running:
		process_play_again(user_input.to_lower())
		return

	display_message("\n>| " + user_input) 
	process_command(user_input.to_lower()) 
	input_field.clear()  

# ================================================================
#                       UTILITY FUNCTIONS
# ================================================================

func display_message(text):
	output_label.append_text(text + "\n")
	output_label.call_deferred("scroll_to_line",output_label.get_line_count()-1)

func disclaimer():
	display_message("\t\tWelcome to the Text Adventure Game!")
	display_message("\t\tType directions: north, south, east, west.")
	display_message("\t\tType 'inventory' to view items.")
	display_message("\t\tType 'quit' to exit to desktop.")
	display_message("\t\tEscape and optionally find treasure.\n")

func print_inventory():
	display_message("\tInventory (%s/3):" % [items.size()])
	if items.is_empty():
		display_message("\t(empty)")
	else:
		for item in items:
			display_message("\t- " + item)
	display_message("")

func has_item(name: String) -> bool:
	return name in items

func add_item(name: String):
	const MAX_ITEMS = 3
	if items.size() >= MAX_ITEMS:
		display_message("\tCannot pick up " + name + " (inventory full)")
		return
	items.append(name)
	display_message("\tPicked up: " + name)

func remove_item(name: String):
	if has_item(name):
		items.erase(name)
		display_message("\tUsed/removed: " + name)
	# The C++ code didn't handle the else case for removal, so we keep it simple

func congrats():
	game_running = false # Game over
	display_message("\n\t\t\t***** CONGRATULATIONS! *****")
	display_message("\t\t\tYou escaped!")
	if has_item("treasure"):
		display_message("\t\t\tYou got the treasure YAY!")
	else:
		display_message("\t\t\tMaybe there's a treasure somewhere...")
	
	display_message("\n\t\tPlay again? (yes/no):")


# ================================================================
#                       WORLD/GAME LOGIC
# ================================================================

func build_world():
	# Storing rooms as dictionaries. Pointers replaced with room names (Strings)
	world_rooms["start"] = {"type": START, "visited": false, "north": "fork", "east": "start", "south": "", "west": ""}
	world_rooms["fork"] = {"type": FORK, "visited": false, "north": "", "east": "orange", "south": "", "west": "blue"}
	world_rooms["blue"] = {"type": BLUE, "visited": false, "north": "win", "east": "", "south": "fork", "west": ""}
	world_rooms["orange"] = {"type": ORANGE, "visited": false, "north": "", "east": "monster", "south": "fork", "west": "orange"}
	world_rooms["monster"] = {"type": MONSTER, "visited": false, "north": "", "east": "", "south": "", "west": "fork"}
	world_rooms["win"] = {"type": WIN, "visited": false, "north": "", "east": "", "south": "", "west": ""}

func start_new_game():
	game_running = true
	items.clear() 
	# Reset visited status for all rooms when starting a new game
	for room_name in world_rooms:
		world_rooms[room_name].visited = false
		
	current_room_name = "start"
	display_room_description()


func display_room_description():
	var current_room_data = world_rooms[current_room_name]
	var room_type = current_room_data.type
	var visited = current_room_data.visited
	var grammar = ""

	if room_type == START:
		if visited: grammar = "You're still in the room with"
		else: grammar = "You wake up in a  room. There is"
		display_message("\t\t" + grammar + " a door to the north and a chest to the east. (north/east)")
	elif room_type == FORK:
		if visited: grammar = "You're back in the room"
		else: grammar = "You enter a new room"
		display_message("\n\t\t" + grammar + " with 2 paths.")
		display_message("\t\tBlue light to the west, orange light to the east. (west/east)")
	elif room_type == BLUE:
		if visited: grammar = "back into the room"
		else: grammar = "into a new room"
		display_message("\t\tYou walk " + grammar + " with a blue light. There is an opening in the ceiling. South is the previous room. (north/south)")
	elif room_type == ORANGE:
		if visited: grammar = "'re still in the room"
		else: grammar = " enter a new room"
		display_message("\t\tYou" + grammar + " with an orange glow. There is a bonfire to north of you,")
		display_message("\t\ta door to the east with a door marked 'Danger',")
		display_message("\t\tand a door marked 'Supplies' to the west. South is the previous room.")
		display_message("\t\t(north/east/west/south)")
	# Monster and Win descriptions are handled *after* movement in your original C++ logic

	# Mark room as visited *after* describing it
	world_rooms[current_room_name].visited = true


func process_command(input: String):
	# Handle Global Commands
	if input == "inventory":
		print_inventory()
		refresh_room_display()
		return
	if input == "quit":
		get_tree().quit()
		return

	# Handle Room-Specific Actions (like opening chests or warming by fire)
	var room_type = world_rooms[current_room_name].type

	if room_type == START:
		if input == "east":
			if not has_item("key"):
				display_message("\t\tYou open the chest and obtain a key.")
				add_item("key")
			else:
				display_message("\t\tChest is empty.")
			refresh_room_display()
			return # Stop processing
		elif input == "north":
			if not has_item("key"):
				display_message("\t\tDoor locked. Need a key.")
				refresh_room_display()
				return # Stop processing
			else:
				display_message("\t\tYou unlock the door with the key")
				remove_item("key")
			# If they have the key, the movement logic below handles the move
	elif room_type == ORANGE:
		if input == "north":
			display_message("\t\tYou warm yourself by the bonfire.")
			refresh_room_display()
			return
		elif input == "west":
			if not has_item("ladder"):
				display_message("\t\tYou find a ladder and a sword in Supplies.")
				add_item("ladder")
				add_item("sword")
			else:
				display_message("\t\tNothing left in Supplies.")
			refresh_room_display()
			return
	elif room_type == BLUE:
		if input == "north":
			if not has_item("ladder"):
				display_message("\tYou cannot reach the opening without a ladder.")
				refresh_room_display()
				return
			# If they have the ladder, the movement logic below handles the move

	# Handle Movement Commands (Only if a specific action didn't 'return' already)
	move_player(input)


func move_player(input_direction: String):
	var current_room_data = world_rooms[current_room_name]
	
	# Check if the input is a valid direction key that exists in the current room's dictionary
	if input_direction in ["north", "south", "east", "west"]:
		var next_room_name = current_room_data[input_direction] 
		
		if next_room_name: # Check if that direction has a valid room name string assigned
			
			# --- C++ MONSTER AND WIN LOGIC (Happens AFTER moving into the new room) ---
			var next_room_data = world_rooms[next_room_name]

			if next_room_data.type == MONSTER:
				display_message("\t\tYou enter a dark room and a monster appears!")
				if not has_item("sword"):
					display_message("\t\tA monster attacks! You have no weapon.\n\t\tGame Over.")
					game_over() # End game here
					return # Stop movement and command processing
				else:
					display_message("\t\tYou slay the monster with your sword and find treasure.")
					display_message("\t\tThe fight takes you back to the forkroom.\n")
					remove_item("sword")
					add_item("treasure")
					print_inventory()
					# C++ logic instantly teleports player back to fork room
					current_room_name = "fork" 
					display_room_description()
					return # Stop movement and command processing
			
			elif next_room_data.type == WIN:
				current_room_name = next_room_name
				congrats() # Calls congrats which sets game_running = false
				return # Stop movement and command processing

			# If no monster/win condition, proceed to the new room normally
			current_room_name = next_room_name
			display_room_description()
			
		else:
			# Matches C++ "\t\tYou can't go that way.\n" logic
			display_message("\t\tYou can't go that way.")
	else:
		# Matches C++ "\t\tInvalid command.\n" logic
		display_message("\t\tInvalid command.")


func game_over():
	game_running = false
	display_message("\n\t\tGame Over.")
	display_message("\nPlay again? (yes/no):")
	

func process_play_again(input: String):
	# This handles input *after* game is over
	if input == "yes" or input == "y":
		# Clear UI for new game and restart the loop
		output_label.clear()
		start_new_game()
		input_field.clear()
		input_field.grab_focus()
	elif input == "no" or input == "n" or input == "quit":
		display_message("\n\tThank you for playing! Goodbye!")
		get_tree().quit()
	else:
		display_message("Invalid input. Play again? (yes/no):")

func refresh_room_display():
	display_message("")
	display_room_description()
