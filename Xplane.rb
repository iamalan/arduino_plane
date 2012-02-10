require 'rubygems'
require 'YAML'
require 'socket'

require 'log'

class Xplane
  DATA_HEADER = [68,65,84,65,0]
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
  
  #rewrite to output data as a hash
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

  
end
