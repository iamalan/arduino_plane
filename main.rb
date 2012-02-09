require 'rubygems'
require 'socket'
require 'serialport'
require 'YAML'

require 'arduino' #new
require 'xplane'

require 'mapper'
require 'filter'

CONFIG = File.open("config.yaml") { |f| YAML.load(f) }
#puts "Configuration:"
#puts CONFIG.to_yaml

x = Xplane.new 'xplane_config.yaml'

arduino = Arduino.new 'arduino_config.yaml'


# The pc_to_arduino_mask is how we filter the packet from X-Plane and defines what we deliver to the arduino.
ALL = [0,1,2,3,4,5,6,7]
NONE = []

# the reason we need to define all of the data we expect in the packet is because we want to know how many bytes to recv later on.
# data is sent over serial in ascending order of the keys of the pc_to_arduino_mask and then in ascending order of the mask itself.
pc_to_arduino_mask = {}
pc_to_arduino_mask[67] = [0,1,2]
pc_to_arduino_mask[127] = [6]
pc_to_arduino_mask[13] = [4] #flap position


m1 = ValueMapper.new 0.0,1.0


map = {}
map[67] = [m1,m1,m1]
map[127] = [m1,m1]
map[13] = [m1]

m = Mapper.new map


f = Filter.new(pc_to_arduino_mask,8)


# Arduino to PC data masking
# data from the arduino arrives in an array of some order. Create a convention that data is always arranged in ascending order of its type and order in the 8 values.
arduino_to_pc_serial_mask = {}
arduino_to_pc_serial_mask[14] = [0]
arduino_to_pc_serial_mask[13] = [0,3]


while true

  data = x.getPacket(3)


   filtered = f.apply_filter(data)
   
    mapped = m.apply_map filtered
    
    arduino.sendHash(mapped)
    
  

    if (serial_data = arduino.getBytes(3)) != []
  

    #screw with the values. implement in the masks later TODO
    serial_data[0] = 0.1 + (serial_data[0]-125.0)/125.0
    serial_data[1] = serial_data[1]/255.0  
    

      
    serial_types = arduino_to_pc_serial_mask.keys.sort
  
    #construct my_data with all xp_no values based on the number of serial_types keys
    my_data = [68,65,84,65,0]
    serial_types.length.times { my_data.concat([0] + [CONFIG["xp_no"]]*8) }
    #iterate over my_data placing correct serial values and packet types
    
    packet_location = 5 
    next_value = 0
    
    # fill the packet types
    serial_types.each_with_index do |key,i|
      my_data[packet_location + i*9] = key
    end
    
    packet_location = 6
      
      serial_types.each do |key|   
       this_mask =  arduino_to_pc_serial_mask[key]
        this_mask.each do |v|
           my_data[packet_location + v] = serial_data[next_value]
           next_value += 1
        end
        packet_location += 9
      end
      
      x.send my_data.pack("#{CONFIG["xp_packet_header"]}" << "#{CONFIG["xp_packet_data_s"]}"*serial_types.length)
    end
end