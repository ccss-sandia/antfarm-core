ROOT = File.expand_path(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift("#{ROOT}/lib")

# Set the ANTFARM environment to 'test'
# so the correct database is used.
ANTFARM_ENV = 'test'

require 'config/environment'

# Do this after 'config/environment' since
# rubygems will then be loaded already.
require 'spec'

# Override logger setup configured by the
# ANTFARM initializer with one more suitable
# for testing purposes.
require 'logger'

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

require 'antfarm/database_manager'

Spec::Runner.configure do |c|
  c.before(:each) do
    # Use DBManager interface to reset the database. This
    # is using the test database due to the ANTFARM_ENV
    # declaration at the top of this file.
    Antfarm::DatabaseManager.new(['-r'])
  end
end
