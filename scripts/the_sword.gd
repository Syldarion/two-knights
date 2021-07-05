class_name Sword
extends KinematicBody2D

export(float) var throw_speed
export(float) var rotation_speed

puppet var puppet_pos = Vector2()
puppet var puppet_rot = 0.0

var direction
var flying

var owner_id

func _ready():
	set_process(false)
	set_physics_process(false)

func _physics_process(delta):
	if is_network_master():
		if flying:
			var collision = move_and_collide(direction * throw_speed * delta)
			if collision:
				check_collision(collision)
			rotation_degrees += rotation_speed * delta
		
		rset_unreliable("puppet_pos", global_transform.origin)
		rset_unreliable("puppet_rot", rotation_degrees)
	else:
		global_transform.origin = puppet_pos
		rotation_degrees = puppet_rot

func throw(throw_dir):
	direction = throw_dir
	flying = true

func halt():
	flying = false

func check_collision(collision: KinematicCollision2D):
	var knight = collision.collider
	if not knight is Knight:
		return
	
	if knight.owner_id == owner_id:
		return
	
	if knight.is_countering:
		direction *= -1
	else:
		knight.kill()
