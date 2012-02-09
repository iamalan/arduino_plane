require 'singleton'

class Log
  include Singleton
  
  @@file = true
 
  def add(line)
    if @@file
      @this_log.puts("#{Time.now} #{Time.now.usec} #{line}")
    else
      puts("#{Time.now} #{Time.now.usec} #{line}")
    end
  end
  
  def close
    add('Closing log.')
    if @@file
      @this_log.close
    end
  end
  
  # call these before anything else!
  def log_to_screen
    @@file = false
    add('Screen log started.')
  end
  
  def log_to_file
    @@file = true
    @this_log = File.open('log.txt', 'w')
    add('File log opened.')
  end
end

# This would be the best place to decide how we should log.
Log.instance.log_to_file

# # Example usage for log to file
# Log.instance.log_to_file
# Log.instance.add 'hey'
# Log.instance.close
# 
# # Example usage for log to screen
# Log.instance.log_to_screen
# Log.instance.add 'hey'
