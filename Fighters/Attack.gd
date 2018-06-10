extends CollisionShape2D

export var damage = 3
export var knockback_base = 3
export var knockback_angle = 30
export var knockback_scaling = 1.0
export var freeze_frame_scaling = 1.0

const knockback_unit_scaling = 15

# returns the amount of hit lag dealt by the attack to the target
func get_dealt_hit_lag(target):
	return 5 * floor((self.damage / 3) + 3) * self.freeze_frame_scaling

# returns the amount of hit stun dealt by the attack to the target
func get_dealt_hit_stun(target, knockback = 0):
	if knockback == 0:
		knockback = self.get_dealt_knockback(target)
	return (knockback / knockback_unit_scaling) * 0.6

# returns the knockback dealt by the attack to the target
func get_dealt_knockback(target):
	var percentage = self.damage + target.damage
	var target_weight = 200 / (target.weight + 100)
	return knockback_unit_scaling * ((((percentage / 10) + ((percentage * self.damage) / 20)) * target_weight * 1.4 + 18) * self.knockback_scaling) + self.knockback_base