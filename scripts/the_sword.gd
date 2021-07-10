class_name Sword
extends KinematicBody2D

export(float) var throw_speed
export(float) var rotation_speed

puppet var puppet_pos = Vector2()
puppet var puppet_rot = 0.0

var direction
var active
var flying

var owner_id

func _ready():
	set_process(false)
	set_physics_process(false)

func _physics_process(delta):
	if is_network_master():
		if active:
			var collision
			if flying:
				rotation_degrees = rad2deg(direction.angle())
				collision = move_and_collide(direction * throw_speed * delta)
			else:
				collision = move_and_collide(Vector2.ZERO)
			if collision:
				check_collision(collision)
		
		rset_unreliable("puppet_pos", global_transform.origin)
		rset_unreliable("puppet_rot", rotation_degrees)
	else:
		global_transform.origin = puppet_pos
		rotation_degrees = puppet_rot

func throw(throw_dir):
	direction = throw_dir
	active = true
	flying = true

func halt():
	active = false
	flying = false

func check_collision(collision: KinematicCollision2D):
	var knight = collision.collider
	if not knight is Knight:
		active = false
		flying = false
		return
	
	if knight.owner_id == owner_id:
		return
	
	if knight.is_countering:
		if flying:
			direction *= -1
		else:
			active = false
	else:
		knight.kill()
