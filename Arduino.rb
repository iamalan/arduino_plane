require 'rubygems'
require 'YAML'
require 'serialport'

require 'log'

class Arduino
  def initialize(config_file)   
    begin
      @CONFIG = File.open(config_file) { |f| YAML.load(f) }
    
      Log.instance.log_to_screen
      Log.instance.add "Opened Arduino config #{config_file}:"
      Log.instance.add @CONFIG.to_yaml
    
      @sp = SerialPort.new(@CONFIG["serial"], @CONFIG["baud"], @CONFIG["data_bits"], @CONFIG["stop_bits"], SerialPort::NONE)
    
      rescue Exception => e
        Log.instance.add "#{e} #{e.backtrace}"
      end   
  end
end

a = Arduino.new 'arduino_config.yaml'

