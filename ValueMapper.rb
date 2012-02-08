class ValueMapper
  BYTE_MIN_VALUE    = 0
  BYTE_MAX_VALUE    = 254 # leaving 255 for the sync byte
  
  def initialize(min_value_range, max_value_range)
    @min_value_range  = min_value_range
    @max_value_range  = max_value_range
  end
  
  def map(value)
    if value >= @max_value_range
      return BYTE_MAX_VALUE
    elsif value <= @min_value_range
      return BYTE_MIN_VALUE
    else
      return ((BYTE_MAX_VALUE - BYTE_MIN_VALUE)*(value - @min_value_range)/(@max_value_range - @min_value_range)).round
    end
  end
  
end

# # Example usage
# 
# # say we read from x-plane a value which exists between packet_min_value and packet_max_value, and we read packet_value
# packet_min_value  = -1.0
# packet_max_value  = 1.0
# 
# packet_value      = 0.9
# 
# # since we send the value over serial as a single byte [0-254] (leaving the 255 for the sync byte) we need to map packet_value
# # 1020 -> 0
# # 3010 -> 254
# # 1245 -> ?
# 
# d = ValueMapper.new packet_min_value, packet_max_value
# p d.map packet_value

