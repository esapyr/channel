class AtomicCounter
  def initialize
    @mutex = Mutex.new
    @count = 0
  end

  def increment!
    @mutex.synchronize { @count += 1 }
  end

  def reset!
    @mutex.synchronize { @count = 0 }
  end
end
