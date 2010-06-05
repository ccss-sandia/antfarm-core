module Antfarm
  class AntfarmError < RuntimeError
    def initialize(message)
      super

      message = "#{self.class}: #{message}"
      Antfarm::Helpers.output("Exception: #{message}")
      Antfarm::Helpers.log :error, message
    end
  end
end
