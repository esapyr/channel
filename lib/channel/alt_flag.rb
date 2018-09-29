class AltFlag

	@@id_counter = AtomicCounter.new

	def initialize
		@mutex = Mutex.new
		@flag = AtomicVariable.new(true)
		@id = @@id_counter.increment!
	end

	def lock
		@mutex.lock
	end

	def unlock
		@mutex.unlock
	end

	def active?
		@flag.get
	end

	def blockable?
		true
	end

	def lock_id
		@id
	end

	def commit
		@flag.set(false)
		true
	end
end
