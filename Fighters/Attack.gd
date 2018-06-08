extends CollisionShape2D

export var damage = 10
export var knockback_base = 15
export var knockback_angle = 45
export var knockback_scaling = 1.0
export var freeze_frame_scaling = 1.0

# returns the knockback dealt by the attack
func get_dealt_knockback(target):
	var percentage = self.damage + target.damage
	var target_weight = 200 / (target.weight + 100)
	return 15 * ((((percentage / 10) + ((percentage * self.damage) / 20)) * target_weight * 1.4 + 18) * self.knockback_scaling) + self.knockback_base

# returns the number of freeze frames dealt by the attack
func get_dealt_freeze_frames(target):
	return floor((self.damage / 3) + 3) * self.freeze_frame_scaling