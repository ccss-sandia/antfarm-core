ROOT = File.expand_path(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift("#{ROOT}/lib")

ANTFARM_ENV = 'test'

require 'logger'
require 'config/environment'
require 'antfarm/database_manager'

# This must be set after the ANTFARM environment is loaded due to the fact
# that requiring the 'bundler' library, which occurs in the initializer called
# by the boot loader called by the ANTFARM environment, clears out the load path
# and only adds paths to the gems specified in the Gemfile as they are
# setup/required.
Bundler.setup(:testing)

LOGGER = Logger.new(STDERR)
if level = ENV['LOG_LEVEL']
  # Use log level provided on command line
  LOGGER.level = eval("Logger::#{level.upcase}") 
else
  LOGGER.level = Logger::INFO
end

Antfarm::Helpers.logger_callback = lambda do |level,msg|
  LOGGER.send(level,msg)
end

# before/after(:each/:all) can be used for setup.
# Global blocks can be setup in Spec::Runner.configure { |c| c.before ... }

Spec::Runner.configure do |c|
  c.before(:each) do
    # Use DBManager interface to reset the database
    Antfarm::DatabaseManager.new(['-r'])
  end
end
