################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

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
  LOGGER.level = Logger::WARN
end

Antfarm::Helpers.logger_callback = lambda do |level,msg|
  LOGGER.send(level,msg)
end

# before/after(:each/:all) can be used for setup.
# Global blocks can be setup in Spec::Runner.configure { |c| c.before ... }

require 'antfarm/framework'

Spec::Runner.configure do |c|
  c.before(:each) do
    # Use the Antfarm framework to reset the database. This
    # is using the test database due to the ANTFARM_ENV
    # declaration at the top of this file.
    Antfarm::Framework.new.reset_db
  end
end
