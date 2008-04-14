# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

ANTFARM_ENV = (ENV['ANTFARM_ENV'] || 'antfarm').dup unless defined? ANTFARM_ENV

require File.dirname(__FILE__) + "/boot"

Antfarm::Initializer.run do |config|
  config.log_level = (ENV['ANTFARM_LOG_LEVEL'] || 'warn').dup
end
