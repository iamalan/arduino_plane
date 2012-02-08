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
  
  def getPacket
    begin
      Log.instance.add "#{self.class.name} #{__method__} called."
      d,a = @s.recv(@CONFIG["xp_packet_header"].length + 36*@this_packet[:data_blocks])
      data = d.unpack(@unpacking_string)
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
  
  def set_pc_to_arduino_mask(pc_to_a_mask)
    @pc_to_a_mask = pc_to_a_mask
    @this_packet = {:header => 1, :data_blocks => @pc_to_a_mask.keys.length}
    @unpacking_string = "#{@CONFIG["xp_packet_header"]}"
    @this_packet[:data_blocks].times { @unpacking_string << @CONFIG["xp_packet_data_s"] }
  end
  
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
      if @pc_to_a_mask[key] != nil
          @pc_to_a_mask[key].sort.each do |mask|
            filtered_vals << ((packet_values[key][mask]*127.5)+127.5).to_i; #TODO this is where we filter values i'd say...
          end
        end
      end
  
    return filtered_vals
  end
  
end

#x = Xplane.new 'xplane_config.yaml'