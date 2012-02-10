require 'rubygems'
require 'socket'
require 'serialport'
require 'YAML'

require 'arduino'
require 'xplane'

require 'mapper'
require 'filter'


def createArrayFromHashAndMask(hash,mask)
  
   serial_types = mask.keys.sort
 
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
      this_mask =  mask[key]
       this_mask.each do |v|
          my_data[packet_location + v] = hash[key][data_count]
          data_count += 1
          next_value += 1
       end
       packet_location += 9
       data_count = 0
     end
  return my_data
end


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

x = Xplane.new 'xplane_config.yaml'
arduino = Arduino.new 'arduino_config.yaml'

#################
# DATA TO ARDUINO DEFINES
# Define all of the packet types that will arrive. If they don't need to be sent to the Arduino, assing a [] to the keys value.
pc_to_arduino_mask = {}
pc_to_arduino_mask[67] = [0,1,2]
pc_to_arduino_mask[127] = [6]
pc_to_arduino_mask[13] = [4] #flap position
f = Filter.new(pc_to_arduino_mask,8)

# we should round as these are becoming bytes
m1 = ValueMapper.new 0.0,1.0,ValueMapper::BYTE_MIN_VALUE,ValueMapper::BYTE_MAX_VALUE, true

# only those packet types with non-empty array values defined below. These go to the Arduino in order of keys.
map = {}
map[67] = [m1,m1,m1]
map[127] = [m1,m1]
map[13] = [m1]
m = Mapper.new map
#
# END DATA TO ARDUINO DEFINES
#################


#################
# DATA FROM ARDUINO DEFINES
# data from the arduino arrives in an array of some order. Create a convention that data is always arranged in ascending order of its type and order in the 8 values.
arduino_to_pc_serial_mask = {}
arduino_to_pc_serial_mask[14] = [0]
arduino_to_pc_serial_mask[13] = [3]
arduino_to_pc_serial_mask[28] = [0]

map2 = {}
# dont round when sending to xplane
map2[14] = [ValueMapper.new(ValueMapper::BYTE_MIN_VALUE,ValueMapper::BYTE_MAX_VALUE, 0.0, 1.0,false)] # gear gets mapped from 0.0 to 1.0
map2[13] = [ValueMapper.new(ValueMapper::BYTE_MIN_VALUE,ValueMapper::BYTE_MAX_VALUE, 0.0,1.0,false)] # trim and flap position
map2[28] = [ValueMapper.new(ValueMapper::BYTE_MIN_VALUE,ValueMapper::BYTE_MAX_VALUE, 699.0, 3000.0,false)]
m2 = Mapper.new map2
#
# END DATA FROM ARDUINO DEFINES
#################


########
# MAIN LOOP
########
while true
  data = x.getPacket(3)
  # data is passed across here as an array. Better as hash.
  filtered = f.apply_filter(data)
  mapped = m.apply_map filtered
  arduino.sendHash(mapped)
    
  if (serial_data = arduino.getBytes(3)) != []
      
    serial_data = hashify(serial_data,arduino_to_pc_serial_mask)
    serial_data = m2.apply_map serial_data
    
    p serial_data
    
    my_data = createArrayFromHashAndMask(serial_data,arduino_to_pc_serial_mask)

    x.send my_data.pack("#{CONFIG["xp_packet_header"]}" << "#{CONFIG["xp_packet_data_s"]}"*serial_data.keys.length)
  end
end
########
# END MAIN LOOP
########

