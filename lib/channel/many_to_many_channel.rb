class ManyToManyChannel
	MAX_QUEUE_SIZE = 1024
	class QueueFullError < StandardError; end

	def initialize(buffer, &xform)
		@buffer = buffer
		@takes = Array.new
		@puts = Array.new
		@channel_lock = Mutex.new
		@closed = AtomicVariable.new(false)
		@xform = xform
	end

	def put!(val, putter)
		raise ArgumentError, "Can't put nil on a channel" if val.nil?
		@channel_lock.lock
		cleanup

		if @closed.get
      @channel_lock.unlock
			return box(false)
		end

		if buffer_not_full? && pending_takes? 
			if atomically_commit putter 
				done = add_to_buffer!(val) # done for short circuting transducer, currently no equiv in ruby

				if buffered_values? 
					take_cbs = commit_pending_takes 
					if !take_cbs.empty?
						abort_and_unlock(done)
						take_cbs.each {|cb| run cb }
					else
						abort_and_unlock(done)
					end
				else
					abort_and_unlock(done)
				end

				return box(true)
			else
				@channel_lock.unlock
				return
			end
		else
			put_cb, take_cb = find_and_commit_taker_for putter 

			if put_cb && take_cb
				@channel_lock.unlock
				run Proc.new { take_cb.call(val) }
				return box(true)
			else
				if buffer_not_full? 
					if atomically_commit putter 
						done = add_to_buffer!(val) # done for short circuting transducer, currently no equiv in ruby
						abort_and_unlock(done)
						return box(true)
					else
						@channel_lock.unlock
						return
					end
				else
					add_to_pending_puts(putter, val)
				end
			end	
		end
	end

	def take!(taker)
		@channel_lock.lock
		cleanup

		if buffered_values?
			if take_cb = atomically_commit taker
				val = @buffer.remove!
				put_cbs = []

				@puts.delete_if do |(putter, val)|
					put_cb = atomically_commit putter
					done = add_to_buffer!(val)
					put_cbs << put_cb if put_cb

					break unless !done && buffer_not_full?
					true
				end
			else
				@channel_lock.unlock
				return
			end
		else
		end
	end

	def close!
		@channel_lock.synchronize do
			cleanup
			return if @closed.get 
			@closed.set(true)

			# need to run 'completion' arity of xform
			@xform.call(@buffer) if (@buffer && @puts.empty?)

			@takes.delete_if do |taker|
				callback = atomically_commit(taker)
				if callback && buffered_values? 
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
  	@takes.keep_if(&:active?) unless @takes.empty?
		@puts.keep_if(&:active?) unless @puts.empty?
	end

	def abort
		@puts.each do |putter|
			callback = atomically_commit(putter)
			run callback unless callback.nil?
		end

	  @puts.clear
		close!
	end

	private

	def commit_pending_puts

	end

	def commit_pending_takes
		take_cbs = []

		@takes.delete_if do |taker|
			if buffered_values? 
				take_cb = atomically_commit taker
				if take_val = @buffer.remove!
					take_cbs << Proc.new { take_cb.call(take_val) }
					next true
				end
			end
		end

		return take_cbs
	end

	def abort_and_unlock(done)
		abort if done
		@channel_lock.unlock
	end

	def buffer_not_full?; @buffer && !@buffer.full?; end
	def buffered_values?; @buffer && @buffer.size.positive?; end
	def pending_takes?; !@takes.empty?; end
	def pending_puts?; !@puts.empty?; end

	def find_and_commit_taker_for(handler)
		ret = committed_taker = nil

		@takes.each do |taker|
			if handler.lock_id < taker.lock_id
				handler.lock; taker.lock
			else
				taker.lock; handler.lock
			end

			if handler.active? && taker.active?
				ret = [handler.commit, taker.commit]
				committed_taker = taker
			end

			handler.unlock
			taker.unlock
			break if ret
		end

		@takes.delete(committed_taker) if ret
		ret
	end

	def add_to_pending_puts(handler, val)
		if handler.active? && handler.blockable?
      unless @puts.size < MAX_QUEUE_SIZE 
  			raise QueueFullError, "No more than #{MAX_QUEUE_SIZE} pending puts are allowed on single channel"
			end

			@puts << [handler, val]
		end
		@channel_lock.unlock
	end

	def run(x, val = nil)
		nil
	end

	def add_to_buffer!(val)
		xformed_val = @xform.call(val)
		@buffer.add!(xformed_val)
		return false
	end

	def box(x)
		x
	end

	def atomically_commit(handler)
		handler.lock
		callback = handler.active? ? handler.commit : nil
		handler.unlock
		callback
	end
end
