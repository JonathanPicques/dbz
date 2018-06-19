extends KinematicBody2D

enum FighterState {
	# Move
	stand,
	crouch,
	crouch_to_stand,
	walk,
	walk_wall,
	walk_turn_around,
	run,
	run_wall,
	run_turn_around,
	jump,
	fall,
	double_jump,
	double_fall,
	fall_through,
	fall_to_stand,
	helpless,
	# Block
	block,
	block_to_stand,
	block_roll,
	block_spot_dodge,
	block_airborne_dodge,
	# Ground attacks
	dash_attack,
	neutral_attack,
	# Tilt attacks
	up_tilt,
	down_tilt,
	forward_tilt,
	# Smash attacks
	up_smash,
	down_smash,
	forward_smash,
	# Aerial attacks
	up_aerial,
	down_aerial,
	back_aerial,
	grab_aerial,
	forward_aerial,
	neutral_aerial,
	# Throws
	grab,
	throw,
	# Specials
	up_special,
	down_special,
	side_special,
	neutral_special,
	# Flinch
	flinch,
	flinch_slide,
	flinch_tumble,
	flinch_tumble_bounce,
	flinch_recover
}
enum FighterDirection {left = -1, none = 0, right = 1}

export var player_index = 1

var input = preload("Input.gd").new(player_index)
var state = FighterState.fall
var state_prev = FighterState.fall

var velocity = Vector2()
var velocity_prev = Vector2()
var velocity_direction = FighterDirection.none

var jumps = 0
var direction = FighterDirection.left
var input_direction = FighterDirection.none

const PhysicsLayer = preload("Physics.gd").PhysicsLayer

const up_vector = Vector2(0, -1)
const down_vector = Vector2(0, 1)
const left_vector = Vector2(-1, 0)
const right_vector = Vector2(1, 0)

func udpate_input(delta):
	self.input.update_input(delta)
	self.input_direction = self.get_input_direction()

func update_velocity():
	self.velocity = self.move_and_slide(self.velocity, up_vector)
	self.position = Vector2(fposmod(self.position.x, 1280), fposmod(self.position.y, 720)) # TODO: remove warping
	self.velocity_direction = self.get_velocity_direction()

func change_direction(direction):
	self.direction = direction
	$Flip.scale.x = -direction

func is_on_floor():
	return self.test_move(self.transform, down_vector)

func is_on_wall(direction = self.input_direction):
	match direction:
		FighterDirection.left: return self.test_move(self.transform, left_vector)
		FighterDirection.right: return self.test_move(self.transform, right_vector)
		_: return false

func is_on_ceiling():
	return .is_on_ceiling()

func is_on_one_way_platform():
	var extents = $CollisionShape2D.shape.extents
	if self.is_on_floor():
		for i in range(-1, 2): # [-1, 0, 1]
			$GroundRayCast2D.set_position(Vector2(i * extents.x, $GroundRayCast2D.position.y))
			$GroundRayCast2D.force_raycast_update()
			if $GroundRayCast2D.is_colliding() and $GroundRayCast2D.get_collider().get_collision_layer_bit(PhysicsLayer.one_way):
				return true
	return false

func get_input_velocity():
	# TODO: get axis raw value
	var vertical = -1 if self.input.up and not self.input.down else 1 if self.input.down and not self.input.up else 0
	var horizontal = -1 if self.input.left and not self.input.right else 1 if self.input.right and not self.input.left else 0
	return Vector2(horizontal, vertical)

func get_input_direction():
	var opposed = self.input.left and self.input.right or (not self.input.left and not self.input.right)
	return FighterDirection.none if opposed else FighterDirection.left if self.input.left else FighterDirection.right

func get_vector_direction(vector):
	return int(sign(vector.x))

func get_velocity_direction():
	return self.get_vector_direction(self.velocity)

func get_horizontal_acceleration(delta, velocity, direction, acceleration, maximum_speed):
	match direction:
		FighterDirection.left: return Vector2(max(velocity.x - acceleration * delta, -maximum_speed), velocity.y)
		FighterDirection.right: return Vector2(min(velocity.x + acceleration * delta, maximum_speed), velocity.y)
		_: return velocity

func get_horizontal_deceleration(delta, velocity, deceleration):
	match self.get_vector_direction(velocity):
		FighterDirection.left: return Vector2(min(velocity.x + deceleration * delta, 0), velocity.y)
		FighterDirection.right: return Vector2(max(velocity.x - deceleration * delta, 0), velocity.y)
		_: return velocity

func get_horizontal_input_movement(delta, velocity, direction, acceleration, deceleration, maximum_speed):
	if self.input_direction == FighterDirection.none:
		return self.get_horizontal_deceleration(delta, velocity, deceleration)
	elif self.input_direction == direction:
		return self.get_horizontal_acceleration(delta, velocity, self.input_direction, acceleration, maximum_speed)
	else:
		return self.get_horizontal_deceleration(delta, velocity, (acceleration + deceleration))

func get_vertical_acceleration(delta, velocity, acceleration, maximum_speed):
	return Vector2(velocity.x, min(self.velocity.y + acceleration * delta, maximum_speed))