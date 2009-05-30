require 'singleton'

module Antfarm
  class DataStore < Hash
    include Singleton

    def self.[]=(k,v)
      instance[k] = v
    end

    def self.[](k)
      instance[k]
    end

    def self.delete(k)
      instance.delete(k)
    end
  end
end
