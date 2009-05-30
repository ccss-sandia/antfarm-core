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

      def self.with_layer2_interface(iface)
        all.each do |node|
          if node.layer2_interfaces.include?(iface)
            return node
          end
        end
        return nil
      end

      before :save, :clamp_certainty_factor
      before :save do
        puts 'Save'
        unless DataStore[:node_name].nil? # TODO <scrapcoder>: should we also check to see if name is already set?
          attribute_set :name, DataStore.delete(:node_name)
          puts "Saving Node with name '#{name}' set by DataStore"
        else
          puts "Saving Node with name '#{name}'"
        end
      end

      def save(context = :default)
        puts 'Save Method'
        super
      end

      private

      def clamp_certainty_factor
        puts 'Node#clamp_certainty_factor called'

        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end
    end
  end
end
