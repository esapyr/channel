class AtomicVariable
	def initialize(var = nil)
		@mutex = Mutex.new
		@var = var 
	end	

	def get
		@mutex.synchronize { @var }
	end

	def set(val)
		@mutex.synchronize { @var = val }
	end
end
