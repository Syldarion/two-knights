class_name Knight
extends KinematicBody2D

export(float) var move_speed
export(float) var jump_force
export(int) var jump_frames_max
export(int) var dash_frames_max
export(float) var dash_speed
export(float) var drop_speed
export(float) var sword_grab_distance
export(int) var counter_frames_max
export(float) var fall_speed

export(NodePath) var held_sword_path

onready var held_sword = get_node(held_sword_path)

puppet var puppet_pos = Vector2()

var velocity = Vector2()
var facing = 1

var can_jump = true
var is_jumping = false
var jump_frames = 0

var can_drop = false
var is_dropping = false

var can_counter = true
remotesync var is_countering = false
remotesync var counter_frames = 0

var can_throw = true
var has_thrown = false
var can_retrieve = false
var is_retrieving = false

var ignore_input = false

var move_axis_input = Vector2()
var sword_axis_input = Vector2()

const INPUT_KB = 0
const INPUT_GP = 1
var current_input = INPUT_KB

signal knight_died

var owner_id

func _ready():
	set_process(false)
	set_physics_process(false)
	
func _input(event):
	if event is InputEventKey or event is InputEventMouse:
		current_input = INPUT_KB
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		current_input = INPUT_GP

func enable():
	set_process(true)
	held_sword.set_process(true)
	set_physics_process(true)
	held_sword.set_physics_process(true)

func disable():
	set_process(false)
	held_sword.set_process(false)
	set_physics_process(false)
	held_sword.set_physics_process(false)

func _physics_process(delta):
	if is_network_master():
		get_input()
		
		velocity.x = 0
		
		if is_countering:
			rset("counter_frames", counter_frames + 1)
			if counter_frames > counter_frames_max:
				rset("is_countering", false)
				can_counter = true
			modulate = Color.blue
		else:
			modulate = Color.white
		
		if is_jumping:
			jump_frames += 1
			velocity.y = -jump_force
			if jump_frames > jump_frames_max:
				is_jumping = false
		else:
			jump_frames = 0
			velocity.y += fall_speed
		
		if is_on_floor():
			can_jump = true
			can_drop = false
			is_dropping = false
		elif not is_dropping and not has_thrown:
			can_drop = true
		
		if is_retrieving:
			var sword_diff = held_sword.position - position
			var sword_dist = sword_diff.length()
			var sword_dir = sword_diff.normalized()
			velocity = sword_dir * dash_speed
			if sword_dist <= sword_grab_distance:
				is_retrieving = false
				has_thrown = false
				velocity = Vector2.ZERO
		
		if is_dropping:
			var point_angle = get_point_and_angle(0.0, 1.0)
			held_sword.position = global_position + Vector2(point_angle.x, point_angle.y) * 16
			held_sword.rotation_degrees = point_angle.z
			velocity.x = 0
			velocity.y = drop_speed
			held_sword.active = true
		else:
			if move_axis_input.x < -0.1:
				velocity.x -= move_speed
				face(-1)
			elif move_axis_input.x > 0.1:
				velocity.x += move_speed
				face(1)
		
		if not has_thrown and not is_dropping:
			held_sword.active = false
			var point_angle = get_point_and_angle(sword_axis_input.x, sword_axis_input.y)
			held_sword.position = position + Vector2(point_angle.x, point_angle.y) * 16
			held_sword.rotation_degrees = point_angle.z
		
		velocity = move_and_slide(velocity, Vector2.UP)
		
		rset_unreliable("puppet_pos", global_transform.origin)
	else:
		global_transform.origin = puppet_pos
		if is_countering:
			modulate = Color.blue
		else:
			modulate = Color.white

func _notification(what):
	match what:
		MainLoop.NOTIFICATION_WM_FOCUS_OUT:
			ignore_input = true
		MainLoop.NOTIFICATION_WM_FOCUS_IN:
			ignore_input = false

func get_input():
	if ignore_input:
		return
	
	move_axis_input = Vector2()
	sword_axis_input = Vector2()
	
	if Input.is_action_just_pressed("counter") and can_counter:
		rset("is_countering", true)
		can_counter = false
		rset("counter_frames", 0)
	
	if Input.is_action_just_pressed("drop") and can_drop:
		is_dropping = true
		can_drop = false
	
	if is_dropping:
		# all other actions can't be done when dropping
		return
	
	if current_input == INPUT_KB:
		get_axis_input_kb()
	elif current_input == INPUT_GP:
		get_axis_input_gp()
		
	var jump_pressed = Input.is_action_pressed("jump")
	
	if jump_pressed and can_jump:
		is_jumping = true
		jump_frames = 0
		can_jump = false
	elif not jump_pressed and is_jumping:
		is_jumping = false
	
	if not has_thrown:
		if Input.is_action_just_pressed("throw"):
			held_sword.throw(sword_axis_input)
			has_thrown = true
	elif Input.is_action_just_pressed("throw") and has_thrown:
		held_sword.halt()
		is_retrieving = true

func get_axis_input_kb():
	move_axis_input = get_wasd_input()
	sword_axis_input = get_mouse_dir()

func get_axis_input_gp():
	move_axis_input = Vector2(Input.get_joy_axis(0, JOY_AXIS_0),
							  Input.get_joy_axis(0, JOY_AXIS_1))
	sword_axis_input = move_axis_input

func get_wasd_input():
	var left = -1 if Input.is_key_pressed(KEY_A) else 0
	var right = 1 if Input.is_key_pressed(KEY_D) else 0
	var up = -1 if Input.is_key_pressed(KEY_W) else 0
	var down = 1 if Input.is_key_pressed(KEY_S) else 0
	
	return Vector2(left + right, up + down)

func get_mouse_dir():
	return (get_global_mouse_position() - position).normalized()

func face(direction):
	facing = direction
	if facing == -1:
		$TheKnight.flip_h = true
	elif facing == 1:
		$TheKnight.flip_h = false

func assign_control(id):
	rpc("assign_control_remote", id)

remotesync func assign_control_remote(id):
	set_network_master(id)
	owner_id = id
	held_sword.set_network_master(id)
	held_sword.owner_id = id

func grab_sword(sword):
	add_child(sword)

func kill():
	rpc("kill_remote")

remotesync func kill_remote():
	emit_signal("knight_died")
	print("KILLED")

func reset():
	held_sword.halt()
	
	velocity = Vector2()
	facing = 1

	can_jump = true
	is_jumping = false
	jump_frames = 0

	can_drop = false
	is_dropping = false

	can_counter = true
	is_countering = false
	counter_frames = 0

	can_throw = true
	has_thrown = false
	can_retrieve = false
	is_retrieving = false

	move_axis_input = Vector2()
	sword_axis_input = Vector2()

func get_point_and_angle(axis_x, axis_y):
	var unit_coord = Vector2.RIGHT
	if abs(axis_x) > 0.1 or abs(axis_y) > 0.1:
		unit_coord = Vector2(axis_x, axis_y).normalized()
	return Vector3(unit_coord.x, unit_coord.y, rad2deg(unit_coord.angle()))
