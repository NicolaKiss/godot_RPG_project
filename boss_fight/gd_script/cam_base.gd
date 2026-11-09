extends Node3D

@export var cam_root_base  = 0.0
@export var cam_root_head  = 0.0

#head
@export var cam_head_max : float = 77
@export var cam_head_min : float = -55

@export var main_senstivity : float = 0.1
var senstivity_base : float = 0.01 * main_senstivity
var senstivity_head : float = 0.01 * main_senstivity


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event):
	if event is InputEventMouseMotion:
		
		cam_root_base = -event.relative.x*senstivity_base
		$".".rotate_y(cam_root_base)
		
		
		cam_root_head = event.relative.y*senstivity_head
		$cam_arm.rotate_x(cam_root_head)
		
		
	pass
func _process(delta):
	if Input.is_action_just_pressed("Ese"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED :
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	cam_root_head = clamp(cam_root_head,deg_to_rad(cam_head_min),deg_to_rad(cam_head_max))
	rotation.y = lerp(rotation.y,deg_to_rad(cam_root_base),delta*senstivity_base)
