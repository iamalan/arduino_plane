require 'valuemapper'

class Mapper
  def initialize(map)
    @map = map
  end
  
  def apply_map(filtered_hash)
    mapped = {}
    begin
      Log.instance.add "#{self.class.name} #{__method__} called with #{filtered_hash.inspect}"

      filtered_hash.keys.each do |k|
        mapped[k] = []
        filtered_hash[k].each_with_index do |v,i|
          mapped[k] << @map[k][i].map(v)
        end
      end
      
    rescue Exception => e
      Log.instance.add "#{e} #{e.backtrace}"
    end
    
    Log.instance.add "#{__method__} returning #{mapped.inspect}"
    return mapped
  end 
end