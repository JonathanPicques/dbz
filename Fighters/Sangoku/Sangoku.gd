extends "../Fighter.gd"

const gravity = 1500
const fall_max_speed = 1400

const jump_strength = 630
const double_jump_strength = 590

const walk_max_speed = 260
const walk_acceleration = 420
const walk_deceleration = 620

func _physics_process(delta):
	# Set inputs
	self.process_inputs()
	
	# Set grounded
	self.process_surroundings()
	
	# Update current state
	self.process_state(delta)
	
	# Update position
	self.process_velocity()
	
	# TODO: Move display damage
	$Damage.set_text(str(damage) + "%")

func process_state(delta):
	match self.state:
		# Move
		FighterState.stand: self.state_stand(delta)
		FighterState.crouch: self.state_crouch(delta)
		FighterState.crouch_to_stand: self.state_crouch_to_stand(delta)
		FighterState.turn_around: self.state_turn_around(delta)
		FighterState.walk: self.state_walk(delta)
		FighterState.jump: self.state_jump(delta)
		FighterState.fall: self.state_fall(delta)
		FighterState.double_jump: self.state_double_jump(delta)
		FighterState.double_fall: self.state_double_fall(delta)
		FighterState.fall_through : self.state_fall_through(delta)
		FighterState.fall_to_stand: self.state_fall_to_stand(delta)
		# Block
		FighterState.block_high: self.state_block_high(delta)
		FighterState.block_high_to_stand: self.state_block_high_to_stand(delta)
		FighterState.block_low: self.state_block_low(delta)
		FighterState.block_low_to_stand: self.state_block_low_to_stand(delta)
		# Ground attacks
		FighterState.neutral_attack: self.state_neutral_attack(delta)
		# Hit / Hurt
		FighterState.flinch: self.state_flinch(delta)
		FighterState.flinch_slide: self.state_flinch_slide(delta)
		FighterState.flinch_tumble: self.state_flinch_tumble(delta)
		FighterState.flinch_tumble_bounce: self.state_flinch_tumble_bounce(delta)

func set_state(state, prev_state = self.state):
	self.state = state
	match state:
		# Move
		FighterState.stand: self.pre_stand()
		FighterState.crouch: self.pre_crouch()
		FighterState.crouch_to_stand: self.pre_crouch_to_stand()
		FighterState.turn_around: self.pre_turn_around()
		FighterState.walk: self.pre_walk()
		FighterState.jump: self.pre_jump()
		FighterState.fall: self.pre_fall()
		FighterState.double_jump: self.pre_double_jump()
		FighterState.double_fall: self.pre_double_fall()
		FighterState.fall_through : self.pre_fall_through()
		FighterState.fall_to_stand: self.pre_fall_to_stand()
		# Block
		FighterState.block_high: self.pre_block_high()
		FighterState.block_high_to_stand: self.pre_block_high_to_stand()
		FighterState.block_low: self.pre_block_low()
		FighterState.block_low_to_stand: self.pre_block_low_to_stand()
		# Ground attacks
		FighterState.neutral_attack: self.pre_neutral_attack()
		# Hit / Hurt
		FighterState.flinch: self.pre_flinch()
		FighterState.flinch_slide: self.pre_flinch_slide()
		FighterState.flinch_tumble: self.pre_flinch_tumble()
		FighterState.flinch_tumble_bounce: self.pre_flinch_tumble_bounce()

########
# Move #
########

func pre_stand():
	$AnimationPlayer.play("1a - Stand")

func state_stand(delta):
	self.jumps = 2
	self.handle_fall(delta)
	self.handle_decelerate_horizontal(delta, walk_deceleration)
	if ((self.direction == FighterDirection.left and self.input.right and not self.input.left) or
		(self.direction == FighterDirection.right and self.input.left and not self.input.right)):
		self.set_state(FighterState.turn_around)
	elif (self.input.left and not self.input.right) or (self.input.right and not self.input.left):
		if not self.walled:
			self.set_state(FighterState.walk)
	elif self.input.block and self.velocity.x == 0:
		self.set_state(FighterState.block_low if self.input.down else FighterState.block_high)
	elif self.input.down and self.velocity.x == 0:
		if self.is_on_one_way_platform():
			self.set_state(FighterState.fall_through)
		else:
			self.set_state(FighterState.crouch)
	elif self.input.attack and self.velocity.x == 0:
		self.set_state(FighterState.neutral_attack)
	elif self.input.jump and self.grounded:
		self.set_state(FighterState.jump)
	elif self.input.debug_input:
		self.set_state(FighterState.flinch)

func pre_crouch():
	$AnimationPlayer.play("6a - Crouch")

func state_crouch(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			self.set_state(FighterState.block_low)
		elif not self.input.down:
			self.set_state(FighterState.crouch_to_stand)

func pre_crouch_to_stand():
	$AnimationPlayer.play_backwards("6a - Crouch")

func state_crouch_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.stand)

func pre_turn_around():
	$FrameTimer.wait_for(5)

func state_turn_around(delta):
	if $FrameTimer.is_stopped():
		self.set_direction(-self.direction)
		self.set_state(FighterState.stand)

func pre_walk():
	$AnimationPlayer.play("5a - Walk")

func state_walk(delta):
	self.handle_fall(delta)
	self.handle_accelerate_horizontal(delta, walk_acceleration, walk_max_speed, true)
	self.handle_decelerate_horizontal(delta, walk_deceleration)
	if self.input.jump and self.grounded:
		self.set_state(FighterState.jump)
	elif self.input.down and self.is_on_one_way_platform():
		self.set_state(FighterState.fall_through)
	elif self.walled or self.velocity.x == 0:
		self.set_state(FighterState.stand)

func pre_jump():
	self.jumps -= 1
	self.velocity.y = -jump_strength
	$AnimationPlayer.play("2a - Jump")

func state_jump(delta):
	self.handle_accelerate_vertical(delta, gravity, fall_max_speed)
	self.handle_accelerate_horizontal(delta, walk_acceleration, walk_max_speed)
	self.handle_decelerate_horizontal(delta, walk_deceleration)
	if self.velocity.y > 0:
		self.set_state(FighterState.fall)

func pre_fall():
	$AnimationPlayer.play("3a - Fall")

func state_fall(delta):
	if self.grounded:
		self.set_state(FighterState.fall_to_stand)
	elif self.input.jump:
		if self.input.left and not self.input.right:
			self.set_direction(FighterDirection.left)
		elif self.input.right and not self.input.left:
			self.set_direction(FighterDirection.right)
		self.set_state(FighterState.double_jump)
	else:
		self.handle_accelerate_vertical(delta, gravity, fall_max_speed)
		self.handle_accelerate_horizontal(delta, walk_acceleration, walk_max_speed)
		self.handle_decelerate_horizontal(delta, walk_deceleration)

func pre_double_jump():
	self.jumps -= 1
	self.velocity.y = -double_jump_strength
	$AnimationPlayer.play("2a - Jump")

func state_double_jump(delta):
	self.handle_accelerate_vertical(delta, gravity, fall_max_speed)
	self.handle_accelerate_horizontal(delta, walk_acceleration, walk_max_speed)
	self.handle_decelerate_horizontal(delta, walk_deceleration)
	if self.velocity.y > 0:
		self.set_state(FighterState.double_fall)

func pre_double_fall():
	$AnimationPlayer.play("3a - Fall")

func state_double_fall(delta):
	if self.grounded:
		self.set_state(FighterState.fall_to_stand)
	else:
		self.handle_accelerate_vertical(delta, gravity, fall_max_speed)
		self.handle_accelerate_horizontal(delta, walk_acceleration, walk_max_speed)
		self.handle_decelerate_horizontal(delta, walk_deceleration)

func pre_fall_through():
	self.position = Vector2(self.position.x, self.position.y + 1)

func state_fall_through(delta):
	self.set_state(FighterState.fall)

func pre_fall_to_stand():
	$AnimationPlayer.play("3b - Fall Recovery")

func state_fall_to_stand(delta):
	self.handle_decelerate_horizontal(delta, walk_deceleration, true)
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.stand)

#########
# Block #
#########

func pre_block_high():
	$AnimationPlayer.play("4b - Block High")

func state_block_high(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			if self.input.down:
				self.set_state(FighterState.block_low)
		else:
			self.set_state(FighterState.block_high_to_stand)

func pre_block_high_to_stand():
	$AnimationPlayer.play_backwards("4b - Block High")

func state_block_high_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.stand if not self.input.block else FighterState.block_high)

func pre_block_low():
	$AnimationPlayer.play("4a - Block Low")

func state_block_low(delta):
	if not $AnimationPlayer.is_playing():
		if not self.input.block:
			self.set_state(FighterState.block_low_to_stand)
		elif not self.input.down:
			self.set_state(FighterState.block_high)

func pre_block_low_to_stand():
	$AnimationPlayer.play_backwards("4a - Block Low")

func state_block_low_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			self.set_state(FighterState.block_low if self.input.down else FighterState.block_high)
		else:
			self.set_state(FighterState.stand)

##################
# Ground attacks #
##################

func pre_neutral_attack():
	$AnimationPlayer.play("7a - Ground neutral")

func state_neutral_attack(delta):
	if $AnimationPlayer.is_playing() and $AnimationPlayer.current_animation_position >= 0.1 and $AnimationPlayer.current_animation_position <= 0.2:
		$AnimationPlayer.set_speed_scale(0.3)
	else:
		$AnimationPlayer.set_speed_scale(1)
	if not $AnimationPlayer.is_playing():
		if self.input.attack:
			self.set_state(FighterState.neutral_attack)
		else:
			self.set_state(FighterState.stand)

##########
# Flinch #
##########

var pre_flinch_angle = 0
var pre_flinch_kback = 0
var pre_flinch_kbacka = 0
var pre_flinch_hit_lag = 0
var pre_flinch_hit_stun = 0

func pre_flinch():
	pre_flinch_kback = last_attack.get_dealt_knockback(self)
	pre_flinch_kbacka = deg2rad(last_attack.knockback_angle)
	pre_flinch_hit_lag = last_attack.get_dealt_hit_lag(self)
	pre_flinch_hit_stun = last_attack.get_dealt_hit_stun(self, pre_flinch_kback)
	self.damage += last_attack.damage
	$FrameTimer.wait_for(pre_flinch_hit_lag)
	$AnimationPlayer.play("8a - Flinch")

var state_flinch_counter = 0

func state_flinch(delta):
	# TODO: find a way to split time efficiently instead of having a counter
	if state_flinch_counter > 0.05:
		state_flinch_counter = 0
		$Flip/Sprite.set_offset(Vector2(rand_range(-5, 5), rand_range(-5, 5)))
	state_flinch_counter += delta
	# END TODO: find a way to split time efficiently
	if $FrameTimer.is_stopped():
		state_flinch_counter = 0
		self.velocity = Vector2(cos(pre_flinch_kbacka) * pre_flinch_kback, -sin(pre_flinch_kbacka) * pre_flinch_kback)
		$Flip/Sprite.set_offset(Vector2(0, 0))
		if pre_flinch_kback < 700:
			self.set_state(FighterState.flinch_slide)
		else:
			self.set_state(FighterState.flinch_tumble)

func pre_flinch_slide():
	$FrameTimer.wait_for(pre_flinch_hit_stun)

func state_flinch_slide(delta):
	self.velocity.x = self.velocity.x - sign(self.velocity.x) * walk_deceleration * delta
	self.velocity.y = min(self.velocity.y + gravity * delta, fall_max_speed)
	if is_on_wall():
		self.velocity = pvelocity.bounce(get_slide_collision(0).normal) * 0.4
	if $FrameTimer.is_stopped() or (self.velocity.y >= 0 and self.grounded):
		velocity /= 2
		self.set_state(FighterState.fall_to_stand if self.grounded else self.get_fall_state())

func pre_flinch_tumble():
	$FrameTimer.wait_for(pre_flinch_hit_stun)

func state_flinch_tumble(delta):
	$Flip/Sprite.rotation += 5 * delta
	self.velocity.x = self.velocity.x - sign(self.velocity.x) * walk_deceleration * delta
	self.velocity.y = min(self.velocity.y + gravity * delta, fall_max_speed)
	if is_on_wall():
		self.velocity = pvelocity.bounce(get_slide_collision(0).normal) * 0.4
	if $FrameTimer.is_stopped() or (self.velocity.y >= 0 and self.grounded):
		$Flip/Sprite.rotation = 0
		if self.grounded:
			self.velocity = Vector2()
		self.set_state(FighterState.flinch_tumble_bounce if self.grounded else self.get_fall_state())

func pre_flinch_tumble_bounce():
	$Flip/Sprite.rotation = 0
	$AnimationPlayer.play("8a - Flinch Bounce")

func state_flinch_tumble_bounce(delta):
	if self.input.jump:
		self.set_state(FighterState.fall_to_stand)