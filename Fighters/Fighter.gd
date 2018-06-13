extends KinematicBody2D

enum FighterState {
	# Move
	stand,
	crouch,
	crouch_to_stand,
	turn_around,
	walk,
	jump,
	fall,
	double_jump,
	double_fall,
	fall_through,
	fall_to_stand,
	# Block
	block_high,
	block_high_to_stand,
	block_low,
	block_low_to_stand,
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
	flinch_tumble_bounce
}

enum FighterDirection {
	left = -1,
	right = 1
}

class FighterInputState:
	var up = false
	var down = false
	var left = false
	var right = false
	
	var jump = false
	var grab = false
	var block = false
	var attack = false
	var attack_alt = false
	
	var taunt1 = false
	var taunt2 = false
	
	var debug_input = false

export var player_index = "1"

var state = FighterState.double_fall
var input = FighterInputState.new()

var jumps = 2
var walled = false
var grounded = false
var velocity = Vector2(0, 0)
var pvelocity = Vector2(0, 0)
var direction = FighterDirection.left
var ground_collider = null

var damage = 220
var weight = 100
var last_attack = preload("Attack.gd").new()

const ground_vector = Vector2(0, -1)

# returns true if a and b are nearly equal
func nearly_equal(a, b, epsilon = 1):
    return abs(a - b) <= epsilon

# update self.input status depending on user key/gamepad actions
func process_inputs():
	self.input.up = Input.is_action_pressed("player_" + str(player_index) + "_up")
	self.input.down = Input.is_action_pressed("player_" + str(player_index) + "_down")
	self.input.left = Input.is_action_pressed("player_" + str(player_index) + "_left")
	self.input.right = Input.is_action_pressed("player_" + str(player_index) + "_right")
	
	self.input.jump = Input.is_action_just_pressed("player_" + str(player_index) + "_jump") or \
		Input.is_action_just_pressed("player_" + str(player_index) + "_up") # TODO: disable tap-to-jump
	self.input.block = Input.is_action_pressed("player_" + str(player_index) + "_block")
	self.input.attack = Input.is_action_pressed("player_" + str(player_index) + "_attack")
	self.input.attack_alt = Input.is_action_pressed("player_" + str(player_index) + "_attack_alt")
	
	self.input.taunt1 = Input.is_action_pressed("player_" + str(player_index) + "_taunt1")
	self.input.taunt2 = Input.is_action_pressed("player_" + str(player_index) + "_taunt2")
	
	self.input.debug_input = Input.is_action_pressed("player_" + str(player_index) + "_debug")

# update surroundings
func process_surroundings():
	self.walled = self.test_move(transform, Vector2(self.direction, 0))
	self.grounded = self.test_move(transform, Vector2(0, 1))
	self.ground_collider = $GroundRayCast2D.get_collider() if self.grounded else null

# update velocity
func process_velocity():
	self.pvelocity = self.velocity
	self.velocity = self.move_and_slide(self.velocity, ground_vector)
	self.position = Vector2(fposmod(self.position.x, 1280), fposmod(self.position.y, 720)) # TODO: remove warping

# change direction and flip sprite if needed
func set_direction(direction):
	self.direction = direction
	$Flip.scale.x = -direction

# get the fall state depending on the number of jumps remaining
func get_fall_state():
	return FighterState.fall if jumps >= 1 else FighterState.double_fall

# returns true if the fighter is standing on a one-way platform
func is_on_one_way_platform():
	return self.ground_collider != null and self.ground_collider.is_in_group("OneWayPlatform")

# transition to fall state if not grounded
func handle_fall(delta):
	if not grounded:
		set_state(get_fall_state())

# handle horizontal acceleration
func handle_accelerate_horizontal(delta, acceleration, maximum_speed, restrict_direction = false):
	if not self.walled and self.input.left and not self.input.right and (not restrict_direction or direction == FighterDirection.left) and self.velocity.x > -maximum_speed:
		self.velocity.x = max(self.velocity.x - acceleration * delta, -maximum_speed)
	elif not self.walled and self.input.right and not self.input.left and (not restrict_direction or direction == FighterDirection.right) and self.velocity.x < maximum_speed:
		self.velocity.x = min(self.velocity.x + acceleration * delta, maximum_speed)

# handle horizontal deceleration
func handle_decelerate_horizontal(delta, deceleration, force = false):
	var modifier = 1 if not force else 2
	if self.velocity.x < 0 and (force or (not self.input.left or self.input.right)):
		self.velocity.x = min(self.velocity.x + deceleration * modifier * delta, 0)
	elif self.velocity.x > 0 and (force or (not self.input.right or self.input.left)):
		self.velocity.x = max(self.velocity.x - deceleration * modifier * delta, 0)

# handle vertical acceleration (aka gravity)
func handle_accelerate_vertical(delta, gravity, maximum_speed):
	self.velocity.y = min(self.velocity.y + gravity * delta, maximum_speed)