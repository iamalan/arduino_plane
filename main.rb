require 'rubygems'
require 'socket'
require 'serialport'
require 'YAML'



def getBytes(sp,size)
  data = []
    while(sp.getbyte != 0xff)
      end
 
   
      size.times do 
        data << sp.getbyte
      end
    
      checksum = (sp.getbyte << 8 | sp.getbyte)

      if checksum != data.inject(:+)
        data = []
      end

   return data
end


def sendArray(sp,array)
  sp.write([255].pack('C'));
  checksum = 0;
  array.each do |value|
    sp.write([value].pack('C'))
    checksum = checksum + value
  end
  sp.write([checksum].pack('s'))
end


CONFIG = File.open("config.yaml") { |f| YAML.load(f) }
puts "Configuration:"
puts CONFIG.to_yaml

sp = SerialPort.new(CONFIG["serial"], CONFIG["baud"], CONFIG["data_bits"], CONFIG["stop_bits"], SerialPort::NONE)
sp.sync = true

# The dat_mask is how we filter the packet from X-Plane and defines what we deliver to the arduino.
ALL = [0,1,2,3,4,5,6,7]
NONE = []
# the reason we need to define all of the data we expect in the packet is because we want to know how many bytes to recv later on.
# data is sent over serial in ascending order of the keys of the data_mask and then in ascending order of the mask itself.
data_mask = {}
data_mask[67] = [0,1,2]
data_mask[127] = [6]
data_mask[13] = [4] #flap position


# based on the number of keys in the mask, the UDP packet we expect will have a header and a number of data_blocks
this_packet = {:header => 1, :data_blocks => data_mask.keys.length}

# create the string that unpacks the packet based on the expected packet
unpacking_string = "#{CONFIG["xp_packet_header"]}"
this_packet[:data_blocks].times { unpacking_string << CONFIG["xp_packet_data_s"] }

s = UDPSocket.new
s.bind('',CONFIG["xp_send_port"])

puts
puts "Entering loop..."

while true
  d,a = s.recv(CONFIG["xp_packet_header"].length + 36*this_packet[:data_blocks])

  data = d.unpack(unpacking_string)
  packet_header = data[0..CONFIG["xp_packet_header"].length-1]
  
  packet_values = {}
  packet_offset = CONFIG["xp_packet_header"].length
  this_packet[:data_blocks].times do
    packet_values[data[packet_offset]] = data[(packet_offset+1)..(packet_offset+CONFIG["xp_packet_data_s"].length-1)]
    packet_offset += CONFIG["xp_packet_data_s"].length
  end
  # get the packets keys which are the packet types
  # this way the result after the mask is in sorted order of the packet type number
  types = packet_values.keys
  types.sort!
  serial_vals = []
  types.each do |key|
    # if the packet number is in the mask lets retain it
    if data_mask[key] != nil
        data_mask[key].sort.each do |mask|
          serial_vals << ((packet_values[key][mask]*127.5)+127.5).to_i;
        end
      end
    end

    # write the serial values as chars, I can't see a reason for the arduino to have floats. 
    # ASSUME that all values are between 0 and 1 and we will map them to 0-255
    # some values are obviously different - eg altitude. In that case we would send a float.
    # an improvement would be having the mask know whether to send a float or not. EDGE case at the moment.
    
    #sp.write [serial_vals.length].pack('C')
    #output_format = ""
    #serial_vals.length.times { output_format << 'C'}
    #sp.write serial_vals.pack(output_format)
    sendArray(sp,serial_vals)
    
    p serial_vals

    


    if (serial_data = getBytes(sp,3)) != []
     p serial_data
    
      
   
    
    my_data = [68,65,84,65,0, 14,
                                     serial_data[0],
                                      CONFIG["xp_no"],
                                      CONFIG["xp_no"],
                                      CONFIG["xp_no"],
                                      CONFIG["xp_no"],
                                      CONFIG["xp_no"],
                                      CONFIG["xp_no"],
                                      CONFIG["xp_no"],
                                      13,
                                      0.1 + (serial_data[1]-125.0)/125.0,
                                      CONFIG["xp_no"],
                                      CONFIG["xp_no"],
                                      serial_data[2]/255.0,
                                      CONFIG["xp_no"], 
                                      CONFIG["xp_no"],
                                      CONFIG["xp_no"],
                                      CONFIG["xp_no"]]
                                   
                      
      
      s.send(my_data.pack("#{CONFIG["xp_packet_header"]}#{CONFIG["xp_packet_data_s"]}#{CONFIG["xp_packet_data_s"]}"), 0, CONFIG["xp_ip"], CONFIG["xp_recv_port"])
    end
  

    
end