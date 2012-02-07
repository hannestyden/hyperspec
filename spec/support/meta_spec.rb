module MetaSpec
  def the_spec(&block)
    intercept(&block).new("The required name.")
  end

  private
  Bound = Struct.new(:value)

  def intercept(&block)
    bound = Bound.new
    yield bound
    bound.value
  end
end
