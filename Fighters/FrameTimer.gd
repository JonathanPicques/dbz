extends Timer

# wait for the given number of frames (1/60 of seconds), wait is over when is_stopped() returns true
func wait_for(frames):
	self.set_wait_time(frames / 60.0)
	self.start()

# returns true if the frame has not been waited for.
func before_frame(frame):
	self._check_frame(frame)
	return (frame / 60.0) > self.get_wait_time() - self.get_time_left()

# returns true if the frame has been waited for.
func after_frame(frame):
	self._check_frame(frame)
	return (frame / 60.0) < self.get_wait_time() - self.get_time_left()

func _check_frame(frame):
	if OS.is_debug_build():
		if (frame / 60.0) < 0.0 or (frame / 60.0) > self.get_wait_time():
			print(frame, " is out of bounds")
			breakpoint