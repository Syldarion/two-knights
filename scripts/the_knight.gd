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

export(NodePath) var held_sword_path

onready var held_sword = get_node(held_sword_path)

puppet var puppet_pos = Vector2()

var velocity = Vector2()
var facing = 1

var jump_frames = 0
var can_jump
var jumping
var dropping
var can_drop
var is_countering
var counter_frames = 0
var in_counter_recovery

var sword_thrown
var retrieving_sword

func _ready():
	pass

func _physics_process(delta):
	if is_network_master():
		get_input()
		check_jump()
		check_drop()
		
		if jumping and can_jump:
			velocity.y = -jump_force
		else:
			velocity.y += 1200 * delta
		
		if retrieving_sword:
			var sword_diff = held_sword.position - position
			var sword_dist = sword_diff.length()
			var sword_dir = sword_diff.normalized()
			velocity = sword_dir * dash_speed
			if sword_dist <= sword_grab_distance:
				retrieving_sword = false
				sword_thrown = false
				velocity = Vector2.ZERO
		
		if dropping:
			velocity.x = 0
			velocity.y = drop_speed
		
		if is_countering:
			counter_frames += 1
			if counter_frames > counter_frames_max:
				is_countering = false
			modulate = Color.blue
		else:
			modulate = Color.white
		
		velocity = move_and_slide(velocity, Vector2.UP)
		
		rset_unreliable("puppet_pos", global_transform.origin)
	else:
		global_transform.origin = puppet_pos

func get_input():
	velocity.x = 0.0
	
	var left_stick = Vector2(Input.get_joy_axis(0, JOY_AXIS_0),
							 Input.get_joy_axis(0, JOY_AXIS_1))
	
	if not dropping:
		if left_stick.x < -0.1:
			velocity.x -= move_speed # need to move these out of here, one place for velocity
			face(-1)
		elif left_stick.x > 0.1:
			velocity.x += move_speed
			face(1)
		jumping = Input.is_action_pressed("jump")
		
	if Input.is_action_just_pressed("drop"):
		if can_drop:
			dropping = true
			can_drop = false
	
	if not dropping:
		if not sword_thrown:
			var point_angle = get_point_and_angle(left_stick.x, left_stick.y)
			held_sword.position = position + Vector2(point_angle.x, point_angle.y) * 16
			held_sword.rotation_degrees = point_angle.z
			
			if Input.is_action_just_pressed("throw"):
				held_sword.throw(left_stick)
				sword_thrown = true
		elif Input.is_action_just_pressed("throw") and sword_thrown:
			held_sword.halt()
			retrieving_sword = true
	else:
		var point_angle = get_point_and_angle(0.0, 1.0)
		held_sword.position = position + Vector2(point_angle.x, point_angle.y) * 16
		held_sword.rotation_degrees = point_angle.z
		
	if Input.is_action_just_pressed("counter") and not is_countering:
		is_countering = true
		counter_frames = 0

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
	elif facing == 1:
		$TheKnight.flip_h = false

func assign_control(id):
	set_network_master(id)

func grab_sword(sword):
	add_child(sword)

func get_point_and_angle(axis_x, axis_y):
	var unit_coord = Vector2.RIGHT
	if abs(axis_x) > 0.1 or abs(axis_y) > 0.1:
		unit_coord = Vector2(axis_x, axis_y).normalized()
	return Vector3(unit_coord.x, unit_coord.y, rad2deg(unit_coord.angle()))
