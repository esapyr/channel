class ManyToManyChannel
	def initialize(buffer)
		@buffer = buffer
		@takes = Array.new
		@puts = Array.new
		@mutex = Mutex.new
		@closed = AtomicVariable.new(false)
	end

	def put!
	end

	def take!
	end

	def close!
		@mutex.synchronize do
			cleanup
			return if @closed.get 
			@closed.set(true)

			# needed to allow for runing xform across empty buffer
			yield @buffer if block_given? && (@buffer && @puts.empty?)

			@takes.delete_if do |taker|
				callback = atomically_get_callback(taker)
				if callback && @buffer && @buffer.size.positive?
					val = buffer.remove!
					run(callback, val)
				end
				true # delete this taker from queue
			end

			@buffer.close if @buffer
		end
	end

	def closed?
		@closed.get
	end

	def cleanup
		unless @takes.empty?
			@takes.delete_if {|taker| !taker.active?}
		end

		unless @puts.empty?
			@puts.delete_if {|putter| !putter.active?}
		end
	end

	def abort
		@puts.each do |putter|
			callback = atomically_get_callback(putter)
			run(callback) unless callback.nil?
		end

	  @puts.clear
		close!
	end

	private

	def run(x, val = nil)
		nil
	end

	def atomically_get_callback(handler)
		handler.lock
		callback = handler.active? ? handler.commit : nil
		handler.unlock
		callback
	end
end
