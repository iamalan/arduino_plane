require 'valuemapper'

class Mapper
  def initialize(map)
    @map = map
  end
  
  def apply_map(filtered_hash)
    mapped = {}

    filtered_hash.keys.each do |k|
      mapped[k] = []
      filtered_hash[k].each_with_index do |v,i|
        mapped[k] << @map[k][i].map(v)
      end
    end
    return mapped
  end 
end