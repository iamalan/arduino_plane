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
  
  def getPacket(data_fields, unpack_string)
    begin
      Log.instance.add "#{self.class.name} #{__method__} called."
      d,a = @s.recv(@CONFIG["xp_packet_header"].length + 36*data_fields)
      data = d.unpack(unpack_string)
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

#x = Xplane.new 'xplane_config.yaml'