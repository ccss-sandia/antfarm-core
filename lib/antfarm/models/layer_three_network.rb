module Antfarm
  module Model
    class LayerThreeNetwork
      include DataMapper::Resource

      storage_names[:default] = 'layer_three_networks'

      property :id,               Serial
      property :certainty_factor, Float, :required => true, :default => 0.8
      property :protocol,         String
      property :custom,           String

      validates_present :certainty_factor

      before :save, :clamp_certainty_factor

      #######
      private
      #######

      def clamp_certainty_factor
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] LayerThreeNetwork#clamp_certainty_factor'
        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end
    end
  end
end
