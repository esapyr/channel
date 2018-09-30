class AltHandler
  def initialize(callback, alt_flag)
    @flag = alt_flag
    @callback = callback
  end

  def lock
    @alt_flag.lock
  end

  def unlock
    @alt_flag.unlock
  end

  def active?
    @alt_flag.active?
  end

  def blockable?
    true
  end

  def lock_id
    @flag.lock_id
  end

  def commit
    @alt_flag.commit
    @callback
  end
end
