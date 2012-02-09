require 'rubygems'
require 'YAML'
require 'socket'

require 'log'

class Xplane
  def initialize(config_file)   
    begin
      @CONFIG = File.open(config_file) { |f| YAML.load(f) }
    
      Log.instance.add "Opened X-Plane config #{config_file}:"
      Log.instance.add @CONFIG.to_yaml
       
      @s = UDPSocket.new
      @s.bind('',@CONFIG["xp_send_port"])
      Log.instance.add "Socket bound."
      
      rescue Exception => e
        Log.instance.add "#{e} #{e.backtrace}"
      end   
  end 
  
  def getPacket(data_fields)
    begin
      Log.instance.add "#{self.class.name} #{__method__} called."
      d,a = @s.recv(@CONFIG["xp_packet_header"].length + 36*data_fields)
      data_with_header = d.unpack(@CONFIG["xp_packet_header"] + @CONFIG["xp_packet_data_s"]*data_fields)
  
      data = data_with_header[@CONFIG["xp_packet_header"].length .. @CONFIG["xp_packet_header"].length + data_fields*@CONFIG["xp_packet_data_s"].length]
      Log.instance.add "Unpacked packet, returning #{data.inspect}"
      return data
    
    rescue Exception => e
      Log.instance.add "#{e} #{e.backtrace}"
    end
  end
  
  # TODO implement properly
  def send(blah)
    @s.send(blah, 0, @CONFIG["xp_ip"], @CONFIG["xp_recv_port"])
  end
  

  
  #obsolete with the new mapper stuff
  def apply_mask(data)
    
    packet_header = data[0..@CONFIG["xp_packet_header"].length-1]

    packet_values = {}
    packet_offset = @CONFIG["xp_packet_header"].length
    @this_packet[:data_blocks].times do
      packet_values[data[packet_offset]] = data[(packet_offset+1)..(packet_offset+@CONFIG["xp_packet_data_s"].length-1)]
      packet_offset += @CONFIG["xp_packet_data_s"].length
    end
    
    # get the packets keys which are the packet types
    # this way the result after the mask is in sorted order of the packet type number
    types = packet_values.keys
    types.sort!
    filtered_vals = []
    types.each do |key|
      # if the packet number is in the mask lets retain it
      if @mask[key] != nil
          @mask[key].sort.each do |mask|
            filtered_vals << ((packet_values[key][mask]*127.5)+127.5).to_i; #TODO this is where we filter values i'd say...
          end
        end
      end
  
    return filtered_vals
  end
  
end

#x = Xplane.new 'xplane_config.yaml'