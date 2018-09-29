class DroppingBuffer
	def initialize(max_length)
		@buffer = Buffer.new(max_length)
	end

	def full?
		false
	end

	def remove!
		@buffer.remove!
	end

	def add!(item)
		unless @buffer.full?
			@buffer.add!(item)
		end
	end

	def close
	end

	def size
		@buffer.size
	end
end
