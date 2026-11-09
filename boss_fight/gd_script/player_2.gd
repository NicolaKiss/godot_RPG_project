extends CharacterBody3D


@onready var body: Node3D = $body
@onready var cam_base: Node3D = $cam_base
@onready var animation_tree: AnimationTree = $body/player_character/AnimationTree


# =========================
# STATES
# =========================

enum MoveState {
	IDLE,
	WALK,
	RUN,
	JUMP,
	FALL,
	LAND
}

enum ActionState {
	NONE,
	ATTACK1,
	ATTACK2,
	ATTACK3,
	POWER_ATTACK,
	DODGE,
	PARRY,
	BLOCK,
	COUNTER
}

var move_state = MoveState.IDLE
var action_state = ActionState.NONE


# =========================
# PLAYER STATS
# =========================

@export var MAXHEALTH := 100.0
var current_health := MAXHEALTH

@export var dmg_received := 4.5

signal update_health_ui


# =========================
# MOVEMENT
# =========================

@export var WALK_SPEED := 4.0
@export var RUN_SPEED := 8.0
@export var SPRINT_SPEED := 12.0

@export var JUMP_VELOCITY := 4.5
@export var ACCELERATION := 5.0
@export var BODY_ROTATION_SPEED := 12.0

const GRAVITY := -9.8

var variable_speed := RUN_SPEED
var last_move_dir := Vector3.BACK

var was_on_floor := true


# =========================
# ANIMATION
# =========================

@export var BLEND_SPEED := 10.0

var current_blend_position := 0.0


# =========================
# READY
# =========================

func _ready():
	current_health = MAXHEALTH


# =========================
# MAIN LOOP
# =========================

func _physics_process(delta):

	update_move_state()
	handle_input()
	handle_movement(delta)
	handle_rotation(delta)
	update_animations(delta)

	move_and_slide()


# =========================
# MOVEMENT STATE
# =========================

func update_move_state():

	var on_floor = is_on_floor()

	# In air
	if not on_floor:

		if velocity.y > 0.0:
			move_state = MoveState.JUMP
		else:
			move_state = MoveState.FALL

	# Just landed
	elif not was_on_floor and on_floor:

		move_state = MoveState.LAND

	# On ground
	else:

		var horizontal_velocity = Vector3(
			velocity.x,
			0.0,
			velocity.z
		)

		if horizontal_velocity.length() < 0.1:
			move_state = MoveState.IDLE

		elif horizontal_velocity.length() < RUN_SPEED:
			move_state = MoveState.WALK

		else:
			move_state = MoveState.RUN

	was_on_floor = on_floor


# =========================
# INPUT
# =========================

func handle_input():

	# Jump
	if Input.is_action_just_pressed("JUMP"):
		if is_on_floor() and action_state == ActionState.NONE:
			velocity.y = JUMP_VELOCITY

	# Attack
	if Input.is_action_just_pressed("ATK"):

		if action_state == ActionState.NONE:
			action_state = ActionState.ATTACK1


	# Dodge
	if Input.is_action_just_pressed("SPRINT"):

		if is_on_floor() and action_state == ActionState.NONE:
			action_state = ActionState.DODGE

# =========================
# MOVEMENT
# =========================

func handle_movement(delta):

	var input_dir = Input.get_vector(
		"D",
		"A",
		"S",
		"W"
	)

	var front = cam_base.global_basis.z
	var right = cam_base.global_basis.x

	var move_dir = front * input_dir.y + right * input_dir.x

	move_dir.y = 0.0

	if move_dir.length() > 0.0:
		move_dir = move_dir.normalized()


	# -------------------------
	# SPEED
	# -------------------------

	var target_speed = WALK_SPEED

	if Input.is_action_pressed("RUN"):
		target_speed = RUN_SPEED

	if Input.is_action_pressed("sprint"):
		target_speed = SPRINT_SPEED

	var target_velocity = move_dir * target_speed


	# -------------------------
	# HORIZONTAL MOVEMENT
	# -------------------------

	var horizontal_velocity = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	horizontal_velocity = horizontal_velocity.move_toward(
		target_velocity,
		ACCELERATION * delta
	)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z


	# -------------------------
	# GRAVITY
	# -------------------------

	if not is_on_floor():

		velocity.y += GRAVITY * delta

	else:

		if velocity.y < 0.0:
			velocity.y = 0.0


	# -------------------------
	# STORE LAST DIRECTION
	# -------------------------

	if move_dir.length() > 0.01:
		last_move_dir = move_dir


# =========================
# ROTATION
# =========================

func handle_rotation(delta):

	if last_move_dir.length() < 0.01:
		return

	var target_angle = Vector3.BACK.signed_angle_to(
		last_move_dir,
		Vector3.UP
	)

	body.global_rotation.y = lerp_angle(
		body.global_rotation.y,
		target_angle,
		BODY_ROTATION_SPEED * delta
	)


# =========================
# ANIMATIONS
# =========================

func update_animations(delta):

	# -------------------------
	# LOCOMOTION BLEND
	# -------------------------

	var horizontal_velocity = Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var target_blend_position = (
		horizontal_velocity.length() / SPRINT_SPEED
	)

	target_blend_position = clamp(
		target_blend_position,
		0.0,
		1.0
	)

	current_blend_position = lerpf(
		current_blend_position,
		target_blend_position,
		BLEND_SPEED * delta
	)

	animation_tree.set(
		"parameters/LOCOMOTION/blend_position",
		current_blend_position
	)


	# -------------------------
	# MOVEMENT CONDITIONS
	# -------------------------

	animation_tree.set(
		"parameters/conditions/is_jumping",
		move_state == MoveState.JUMP
	)

	animation_tree.set(
		"parameters/conditions/in_falling",
		move_state == MoveState.FALL
	)

	animation_tree.set(
		"parameters/conditions/is_landing",
		move_state == MoveState.LAND
	)

	animation_tree.set(
		"parameters/conditions/is_moving",
		move_state == MoveState.IDLE
		or move_state == MoveState.WALK
		or move_state == MoveState.RUN
	)


	# -------------------------
	# COMBAT CONDITIONS
	# -------------------------

	animation_tree.set(
		"parameters/conditions/attack1",
		action_state == ActionState.ATTACK1
	)

	animation_tree.set(
		"parameters/conditions/attack2",
		action_state == ActionState.ATTACK2
	)

	animation_tree.set(
		"parameters/conditions/attack3",
		action_state == ActionState.ATTACK3
	)

	animation_tree.set(
		"parameters/conditions/power_attack",
		action_state == ActionState.POWER_ATTACK
	)

	animation_tree.set(
		"parameters/conditions/dodge",
		action_state == ActionState.DODGE
	)

	animation_tree.set(
		"parameters/conditions/parry",
		action_state == ActionState.PARRY
	)

	animation_tree.set(
		"parameters/conditions/block",
		action_state == ActionState.BLOCK
	)

	animation_tree.set(
		"parameters/conditions/counter",
		action_state == ActionState.COUNTER
	)


# =========================
# DAMAGE
# =========================

func take_damage(damage):

	current_health -= damage

	update_health_ui.emit(current_health)

	if current_health <= 0:
		current_health = 0
		die()


# =========================
# DEATH
# =========================

func die():

	print("Player died")


# =========================
# ENEMY CONTACT
# =========================

func _on_enemy_player_contact(enemy_dmg):

	take_damage(enemy_dmg)
