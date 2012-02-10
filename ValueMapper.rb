class ValueMapper
  BYTE_MIN_VALUE    = 0
  BYTE_MAX_VALUE    = 254 # leaving 255 for the sync byte
  
  def initialize(min_value_range, max_value_range, min_output, max_output, round)
    @min_value_range  = min_value_range
    @max_value_range  = max_value_range
    @min_output = min_output
    @max_output = max_output
    @round = round
  end
  
  def map(value)
    Log.instance.add "#{self.class.name} #{__method__} called with #{value}"
    
    if value >= @max_value_range
      ret =  @max_output
    elsif value <= @min_value_range
      ret =  @min_output
    else
      Log.instance.add "max_output:#{@max_output} min_output:#{@min_output} min_value_range:#{@min_value_range} max_value_range:#{@max_value_range}"
      #ret = ((@max_output - @min_output)*(value - @min_value_range)/(@max_value_range - @min_value_range))
      ret = (value.to_f/(@max_value_range - @min_value_range)) * (@max_output - @min_output) + @min_output
      Log.instance.add "Value is #{ret}"
      if @round
        ret = ret.round
        Log.instance.add "Rounded to #{ret}"
      end
      
    end
    
    Log.instance.add "Returning #{ret}"
    return ret
  end
  
end