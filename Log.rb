class Log
  def initialize(file_name)
    @this_log = File.open(file_name, 'w')
    add("Log opened.")
  end
  
  def add(line)
    @this_log.puts("#{Time.now} #{Time.now.usec} #{line}")
  end
  
  def close
    add('Closing log.')
    @this_log.close
  end
end

# # Example usage.
# log = Log.new 'log.txt'
# log.add 'Did something.'
# log.close
