#extends CharacterBody3D
#
#signal player_contact
#
#@export var SPEED = 4.0
#@export var enemy_health = 50
#@export var enemy_dmg = 10.0
#@onready var nav_agent = $NavigationAgent3D
#
## We will assign the player node to this later from a spawner or main script
#var player: Node3D = null 
#
#func _ready():
	## Wait a frame for the navigation map to sync up
	#await get_tree().physics_frame
	## Find the player in the scene (assuming they are in a group called "Player")
	#player = get_tree().get_first_node_in_group("Player")
#
#func _physics_process(_delta):
	#if not player:
		#return
		#
	## Tell the agent where the player is
	#nav_agent.target_position = player.global_position
	#
#
	## Get the next point on the path to the player
	#var next_path_pos = nav_agent.get_next_path_position()
	#var current_pos = global_position
	#
	## Calculate the direction vector and assign it directly to velocity
	#var new_velocity = (next_path_pos - current_pos).normalized() * SPEED
	#velocity = new_velocity
	#
	## 1. Let move_and_slide handle the actual smooth movement and floor logic
	#move_and_slide()
	#
	## 2. Check everything we collided with DURING the slide this frame
	#for i in get_slide_collision_count():
		#var collision = get_slide_collision(i)
		#var collider = collision.get_collider()
		#
		## If the thing we bumped into is the Player, trigger the damage!
		#if collider and collider.is_in_group("Player"):
			#print("contact")
			#player_contact.emit(enemy_dmg)
			#break# Break the loop so we don't trigger multiple hits in a single frame
			#
	#if nav_agent.is_navigation_finished():
		#return 
		#

extends CharacterBody3D

signal player_contact

@export var SPEED = 4.0
@export var ROTATION_SPEED = 6.0
@export var FOLLOW_RANGE = 10.0

@export var enemy_health = 50
@export var enemy_dmg = 10.0

@onready var nav_agent = $NavigationAgent3D
@onready var animation_player = $GD_plyer/AnimationPlayer

var player: Node3D = null


func _ready():
	await get_tree().physics_frame
	player = get_tree().get_first_node_in_group("Player")

	animation_player.play("idle")


func _physics_process(delta):
	if not player:
		return

	# Distance between enemy and player
	var distance_to_player = global_position.distance_to(
		player.global_position
	)

	# --------------------------------
	# PLAYER TOO FAR -> IDLE
	# --------------------------------
	if distance_to_player > FOLLOW_RANGE:
		velocity.x = 0
		velocity.z = 0

		if animation_player.current_animation != "idle":
			animation_player.play("idle")

		move_and_slide()
		return


	# --------------------------------
	# PLAYER IN RANGE -> FOLLOW
	# --------------------------------

	# Tell navigation agent where player is
	nav_agent.target_position = player.global_position

	# Get next point on navigation path
	var next_path_pos = nav_agent.get_next_path_position()

	var direction = next_path_pos - global_position
	direction.y = 0

	if direction.length() > 0.1:
		direction = direction.normalized()

		# --------------------------------
		# TURN TOWARD PLAYER
		# --------------------------------

		var target_direction = player.global_position - global_position
		target_direction.y = 0

		if target_direction.length() > 0.1:
			target_direction = target_direction.normalized()

			var target_angle = atan2(
				target_direction.x,
				target_direction.z
			)

			rotation.y = lerp_angle(
				rotation.y,
				target_angle,
				ROTATION_SPEED * delta
			)

		# --------------------------------
		# MOVE
		# --------------------------------

		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

	else:
		velocity.x = 0
		velocity.z = 0


	move_and_slide()


	# --------------------------------
	# ANIMATION
	# --------------------------------

	var horizontal_velocity = Vector2(
		velocity.x,
		velocity.z
	).length()

	if horizontal_velocity > 0.1:
		if animation_player.current_animation != "run":
			animation_player.play("run")
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")


	# --------------------------------
	# PLAYER CONTACT
	# --------------------------------

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider and collider.is_in_group("Player"):
			print("contact")
			player_contact.emit(enemy_dmg)
			break
