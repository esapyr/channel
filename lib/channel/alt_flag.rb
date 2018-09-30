class AltFlag
	attr_reader :lock_id
	@@id_counter = AtomicCounter.new

	def initialize
		@mutex = Mutex.new
		@flag = AtomicVariable.new(true)
		@lock_id = @@id_counter.increment!
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

	def commit
		@flag.set(false)
		true
	end
end
