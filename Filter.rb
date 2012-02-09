class Filter
  def initialize(mask, data_size)
    @mask = mask
    @data_size = data_size
  end
  
  def apply_filter(data)
    hash = {}
    begin
      Log.instance.add "#{self.class.name} #{__method__} called with #{data.inspect}"
      
      @mask.keys.length.times do |i|
        hash[data[i*(@data_size+1)]] = data[  i*(@data_size+1) + 1  ..   i*(@data_size+1) + 1 + @data_size-1 ]   
      end
    
      filtered_hash = {}
    
      hash.keys.each do |k| 
        if @mask[k] != nil
          filtered_hash[k] = []
          @mask[k].each do |mask_location|
            filtered_hash[k] << hash[k][mask_location]
          end
        end 
      end   

      rescue Exception => e
          Log.instance.add "#{e} #{e.backtrace}"
      end
   
   Log.instance.add "#{__method__} returning #{filtered_hash.inspect}"
   return filtered_hash
  end  
end








