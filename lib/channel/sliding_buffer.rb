class SlidingBuffer
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
		if @buffer.full?
			remove!
		end

		@buffer.add!(item)
	end

	def close
	end

	def size
		@buffer.size
	end
end
