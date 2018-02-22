class Directory
  def initialize(path:, to_be_removed: false)
    @path, @to_be_removed = path, to_be_removed
  end

  attr_reader :path, :to_be_removed

  def to_h
    { path: path, to_be_removed: to_be_removed }
  end

  def self.from_h(h)
    new(path: h.fetch('path'), to_be_removed: h.fetch('to_be_removed'))
  end
end
