class Buffer
  def initialize(max_length)
    @buffer = Array.new
    @max_length = max_length
  end

  def full?
    @buffer.size >= @max_length
  end

  def remove!
    @buffer.pop
  end

  def add!(item)
    @buffer.unshift(item)
  end

  def close; end

  def size
    @buffer.size
  end
end

FixedBuffer = Buffer
