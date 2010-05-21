module Antfarm
  class AntfarmError < RuntimeError
    def initialize(*args)
      Antfarm::Helpers.log :error, "#{self.class}: #{args}"
    end
  end
end
