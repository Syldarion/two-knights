class_name Knight
extends KinematicBody2D

export(float) var move_speed
export(float) var jump_force
export(int) var jump_frames_max
export(int) var dash_frames_max
export(float) var dash_speed
export(float) var drop_speed

puppet var puppet_pos = Vector2()

var velocity = Vector2()
var facing = 1

var dash_frames
var can_dash
var dashing
var jump_frames = 0
var can_jump
var jumping
var dropping
var can_drop

func _ready():
	pass

func _physics_process(delta):
	if is_network_master():
		get_input()
		check_dash()
		check_jump()
		check_drop()
		
		if jumping and can_jump:
			velocity.y = -jump_force
		else:
			velocity.y += 1200 * delta
		
		if dashing:
			velocity.y = 0
			velocity.x = facing * dash_speed
		elif dropping:
			velocity.x = 0
			velocity.y = drop_speed
		
		velocity = move_and_slide(velocity, Vector2.UP)
		
		if global_transform.origin.x < -16:
			global_transform.origin.x = 336
		elif global_transform.origin.x > 336:
			global_transform.origin.x = -16
		if global_transform.origin.y > 256:
			global_transform.origin.y = -16
		
		rset_unreliable("puppet_pos", global_transform.origin)
	else:
		global_transform.origin = puppet_pos

func get_input():
	velocity.x = 0.0
	
	if not dashing and not dropping:
		if Input.is_action_pressed("move_left"):
			velocity.x -= move_speed # need to move these out of here, one place for velocity
			face(-1)
		elif Input.is_action_pressed("move_right"):
			velocity.x += move_speed
			face(1)
		jumping = Input.is_action_pressed("jump")
		
	if Input.is_action_just_pressed("dash"):
		if can_dash:
			dashing = true
			can_dash = false
			dash_frames = 0
		elif dashing:
			dashing = false
			can_dash = false
			dash_frames = 0
		
	if Input.is_action_just_pressed("drop"):
		if can_drop:
			dropping = true
			can_drop = false
			if dashing:
				dashing = false

func check_dash():
	if dashing:
		can_dash = false
		dash_frames += 1
		if dash_frames > dash_frames_max:
			dashing = false
	else:
		if is_on_floor():
			can_dash = true

func check_jump():
	if jumping and can_jump:
		jump_frames += 1
		if jump_frames > jump_frames_max:
			can_jump = false
			jumping = false
	else:
		can_jump = false
		jump_frames = 0
		if is_on_floor():
			can_jump = true

func check_drop():
	if is_on_floor():
		can_drop = false
		dropping = false
	elif not dropping:
		can_drop = true

func face(direction):
	facing = direction
	if facing == -1:
		$TheKnight.flip_h = true
		$Sword.rotation_degrees = 180
		$Sword.position = Vector2(-16, 0)
	elif facing == 1:
		$TheKnight.flip_h = false
		$Sword.rotation_degrees = 0
		$Sword.position = Vector2(16, 0)

func assign_control(id):
	set_network_master(id)
