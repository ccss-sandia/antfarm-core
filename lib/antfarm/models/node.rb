module Antfarm
  module Model
    class Node
      include DataMapper::Resource

      storage_names[:default] = 'nodes'

      property :id,               Serial
      property :certainty_factor, Float, :required => true, :default => 0.8
      property :name,             String
      property :device_type,      String
      property :custom,           String

      has n, :layer2_interfaces, :constraint => :destroy

      validates_present :certainty_factor

      before :save, :clamp_certainty_factor

      #######
      private
      #######

      def clamp_certainty_factor
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] Node#clamp_certainty_factor'
        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end
    end
  end
end
