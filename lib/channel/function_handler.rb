class FunctionHandler
	attr_reader :lock_id

	def initialize(fn, blockable: true)
		@fn = fn
		@blockable = blockable
		@lock_id = 0
	end
	
	# no-ops for this type of handler
	def lock; end
	def unlock; end

	def active?
		true
	end

	def blockable?
		@blockable == true
	end

	def commit
		@fn
	end
end
