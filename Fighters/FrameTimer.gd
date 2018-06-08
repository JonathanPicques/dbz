extends Timer

# starts a timer to wait for the given number of frames (nth of a second)
func start_for_frames(frames):
	self.set_wait_time(frames / 60.0)
	self.start()