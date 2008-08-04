# 
# Copyright 2008 Sandia National Laboratories
# Original Author:: Bryan T. Richardson <btricha@sandia.gov>
# Modeled after the Rails boot script
#

ANTFARM_ROOT = (ENV['ANTFARM_ROOT'] || File.dirname(__FILE__) + "/..").dup unless defined? ANTFARM_ROOT
USER_DIR = (ENV['HOME'] + "/.antfarm").dup unless (!File.exist?(ENV['HOME'] + "/.antfarm") || defined? USER_DIR)

module Antfarm

  class << self
    def boot!
      unless booted?
        require ANTFARM_ROOT + "/lib/init/initializer"
        Antfarm::Initializer.run(:set_load_path)
      end
    end

    def booted?
      defined? Antfarm::Initializer
    end
  end

end

Antfarm.boot!
