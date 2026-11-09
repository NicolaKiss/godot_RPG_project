extends CharacterBody3D

@export_group("refrenceing")
@onready var body :Node3D = $body
@onready var cam_base: Node3D = $cam_base
@onready var animation_tree: AnimationTree = $"body/player_character_2ND(ALTER_ACTIONS_import)/AnimationTree"


@export_group("player stats")
@export var MAXHEALTH = 100.0
@onready var current_health = MAXHEALTH
@export var dmg_recived = 4.5

signal update_health_ui

### STATE MACHINE 1: Define our possible states
enum State { LOCOMOTION,SPRINT, JUMP, FALL, LANDED, ATK}
var current_state = State.LOCOMOTION

@export_group("Movement")
@export var RUN_SPEED = 10.0
@export var SPRINT_SPEED = 16.0
@export var VARIABLE_SPEED : float = RUN_SPEED


@export var JUMP_VELOCITY = 4.5
var _last_move_dir := Vector3.BACK
@export var ACCELERATION = 5.0
@export var body_rotation_speed = 12.0

@export var BLEND_SPEED: float = 10.0 # Higher number = faster animation snaps

var current_blend_position: float = 0.0

const gGravity = -9.8 #(gravity adgestment constant)

var in_air : bool = false
var just_landed : bool = false

var was_in_air : bool = false
var is_jumping : bool = false
var was_falling : bool = false #was falling and landing animation is done playing
var landed : bool = false
var holding_sprint :bool = false


func _ready():pass
	
func _physics_process(delta):
	

	
	if is_on_floor() and landed and not holding_sprint:
		current_state = State.LOCOMOTION
		
	if not is_on_floor() and not holding_sprint :
		current_state = State.FALL
		was_in_air = true
		landed = false
	
	if was_in_air and is_on_floor():
		current_state = State.LANDED
		landed = true
		was_in_air = false
	
	# Handle jump.
	if Input.is_action_just_pressed("JUMP") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMP

	# ATK
	if Input.is_action_just_pressed("ATK"):
		current_state = State.ATK


	### movement
	# taking input
	var input_dir = Input.get_vector( "D", "A","S", "W")
	var front = cam_base.global_basis.z
	var right = cam_base.global_basis.x
	var move_dir = front*input_dir.y+right*input_dir.x
	#setting vertical 0
	#cuz cam is slanted so it might cuz issue later so set it 0 as prevention
	move_dir.y = 0.0
	move_dir=move_dir.normalized()
	#storing previous vertival velocity 
	#beforing adding 2d horizontal movement 
	var Prev_g_velocity = velocity.y
	#setting vertical to zero from previous vertival velocity
	velocity.y = 0.0
	

	
	# adding 2d horizontal movement 
	velocity = velocity.move_toward(move_dir*VARIABLE_SPEED,ACCELERATION)
	# adding the previouly removed and stored vertival velocity back in 
	# by setting y velocity as previous y velocity and increseaing it by gGravity*delta
	velocity.y = Prev_g_velocity + gGravity * delta

	###rotation of player to cam look direction
	if move_dir.length() > 0.01:
		_last_move_dir = move_dir

	var targ_angle := Vector3.BACK.signed_angle_to(_last_move_dir,Vector3.UP)
	body.global_rotation.y = lerp_angle(body.global_rotation.y,targ_angle,body_rotation_speed*delta)

	if Input.is_action_just_pressed("SPRINT"):
		holding_sprint = true
		VARIABLE_SPEED = SPRINT_SPEED
		current_state = State.SPRINT
	if Input.is_action_just_released("SPRINT"):
		holding_sprint = false
		VARIABLE_SPEED = RUN_SPEED
		current_state = State.LOCOMOTION

	### STATE MACHINE 3: Update the Animation Tree
	update_animations(delta)
	
	###health 
	



	move_and_slide()

 




# We put this in a separate function so _physics_process doesn't get cluttered
func update_animations(delta):
	print(current_state == State.SPRINT)
	 #1. Handle the 1D BlendSpace for moving (Idle/Walk/Run)
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	var target_blend_position = horizontal_velocity.length() / VARIABLE_SPEED
	current_blend_position = lerpf(current_blend_position, target_blend_position, BLEND_SPEED * delta)
	if holding_sprint == false :
		animation_tree.set("parameters/LOCOMOTION/blend_position", current_blend_position)
	
	## 2. Toggle the advance conditions based on our State Enum!
	## This tells the visual arrows in your AnimationTree when to fire.
	animation_tree.set("parameters/conditions/is_sprinting", current_state == State.SPRINT)
	animation_tree.set("parameters/conditions/is_jumping", current_state == State.JUMP)
	animation_tree.set("parameters/conditions/in_falling", current_state == State.FALL)
	animation_tree.set("parameters/conditions/is_landing", current_state == State.LANDED)
	animation_tree.set("parameters/conditions/is_moving", current_state == State.LOCOMOTION)
	animation_tree.set("parameters/conditions/is_atking", current_state == State.ATK)
	print(current_state)


func _on_enemy_player_contact(enemy_dmg):
	current_health = current_health - enemy_dmg
	update_health_ui.emit(current_health)
	pass # Replace with function body.
