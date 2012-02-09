require 'rubygems'
require 'socket'
require 'serialport'
require 'YAML'

require 'arduino' #new
require 'xplane'

require 'mapper'
require 'filter'


def hashify(array,map)
  hash = {}
  the_keys = map.keys.sort

  array_pos = 0
  the_keys.each do |k|
    values_to_take = map[k].length
    hash[k] = array[array_pos ... array_pos + values_to_take]
    array_pos += values_to_take
  end
  return hash
end

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
f = Filter.new(pc_to_arduino_mask,8)

# we should round as these are becoming bytes
m1 = ValueMapper.new 0.0,1.0,ValueMapper::BYTE_MIN_VALUE,ValueMapper::BYTE_MAX_VALUE, true
map = {}
map[67] = [m1,m1,m1]
map[127] = [m1,m1]
map[13] = [m1]
m = Mapper.new map


# Arduino to PC data masking
# data from the arduino arrives in an array of some order. Create a convention that data is always arranged in ascending order of its type and order in the 8 values.
arduino_to_pc_serial_mask = {}
arduino_to_pc_serial_mask[14] = [0]
arduino_to_pc_serial_mask[13] = [0,3]

map2 = {}
# dont round when sending back to xplane
map2[14] = [ValueMapper.new(ValueMapper::BYTE_MIN_VALUE,ValueMapper::BYTE_MAX_VALUE, 0.0, 1.0,false)] # gear gets mapped from 0.0 to 1.0
map2[13] = [ValueMapper.new(ValueMapper::BYTE_MIN_VALUE,ValueMapper::BYTE_MAX_VALUE, -1.0, 1.0,false), ValueMapper.new(ValueMapper::BYTE_MIN_VALUE,ValueMapper::BYTE_MAX_VALUE, 0.0,1.0,false)] # trim and flap position
m2 = Mapper.new map2

while true

  data = x.getPacket(3)


   filtered = f.apply_filter(data)
   
    mapped = m.apply_map filtered
  
    
    arduino.sendHash(mapped)
    
  

    if (serial_data = arduino.getBytes(3)) != []
      
    serial_data = hashify(serial_data,arduino_to_pc_serial_mask)
    
    serial_data = m2.apply_map serial_data
    
        
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
    data_count = 0
      
      serial_types.each do |key|   
       this_mask =  arduino_to_pc_serial_mask[key]
        this_mask.each do |v|
           my_data[packet_location + v] = serial_data[key][data_count]
           data_count += 1
           next_value += 1
        end
        packet_location += 9
        data_count = 0
      end
    
      
      x.send my_data.pack("#{CONFIG["xp_packet_header"]}" << "#{CONFIG["xp_packet_data_s"]}"*serial_types.length)
    end
end