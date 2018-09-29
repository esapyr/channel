class FunctionHandler < Handler
	def initialize(fn, blockable = true)
		super()
		@fn = fn
		@blockable = blockable
	end

	def active?
		true
	end

	def blockable?
		@blockable == true
	end

	def lock_id
		0
	end

	def commit
		@fn
	end
end
