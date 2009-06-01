module Antfarm
  module Models
    class Node
      include DataMapper::Resource

      property :id,               Serial
      property :certainty_factor, Float, :nullable => false, :default => 0.8
      property :name,             String

      has n, :layer2_interfaces

      validates_present :certainty_factor

      has_tags_on :tags

      before :save, :clamp_certainty_factor
      before :save do
        unless DataStore[:node_name].nil? # TODO <scrapcoder>: should we also check to see if name is already set?
          attribute_set :name, DataStore.delete(:node_name)
          Antfarm::Helpers.log :debug, "Saving Node with name '#{name}' set by DataStore"
        else
          Antfarm::Helpers.log :debug, "Saving Node with name '#{name}'"
        end
      end

      private

      def clamp_certainty_factor
        Antfarm::Helpers.log :debug, 'Node#clamp_certainty_factor called'

        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end
    end
  end
end
