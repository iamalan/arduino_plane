require 'rubygems'
require 'YAML'
require 'serialport'

require 'log'
require 'valuemapper'

class Arduino
  def initialize(config_file)   
    begin
      @CONFIG = File.open(config_file) { |f| YAML.load(f) }
    
      Log.instance.add "Opened Arduino config #{config_file}:"
      Log.instance.add @CONFIG.to_yaml
    
      @sp = SerialPort.new(@CONFIG["serial"], @CONFIG["baud"], @CONFIG["data_bits"], @CONFIG["stop_bits"], SerialPort::NONE)
    
      rescue Exception => e
        Log.instance.add "#{e} #{e.backtrace}"
      end   
  end
  
  def sendArray(array)
    begin
      Log.instance.add "#{self.class.name} #{__method__} called with #{array.inspect}."
      @sp.write([255].pack('C'));
      Log.instance.add "Wrote sync byte over serial."
      checksum = 0;
      array.each do |value|
        @sp.write([value].pack('C'))
        Log.instance.add "Wrote #{value} over serial."
        if value > ValueMapper::BYTE_MAX_VALUE then Log.instance.add "Warning, last value written was over BYTE_MAX_VALUE of #{ValueMapper::BYTE_MAX_VALUE}." end
        checksum = checksum + value
      end
      @sp.write([checksum].pack('s'))
      Log.instance.add "Wrote #{checksum} over serial."
    rescue Exception => e
        Log.instance.add "#{e} #{e.backtrace}"
    end
  end
end

a = Arduino.new 'arduino_config.yaml'
a.sendArray([300,255,255])

