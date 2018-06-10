extends Timer

# wait for the given number of frames (1/60 of seconds), wait is over when is_stopped() returns true
func wait_for(frames):
	self.set_wait_time(frames / 60.0)
	self.start()