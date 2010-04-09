module Antfarm
  module Models
    class Traffic
      include DataMapper::Resource

      property :id,   Serial
      property :port, Integer

      belongs_to :source, :model => 'Layer3Interface', :child_key => [:source_id]
      belongs_to :target, :model => 'Layer3Interface', :child_key => [:target_id]

      has_tags_on :tags

      after :create do
        Antfarm::Helpers.log :debug, 'Just created a Traffic entry'
      end
    end
  end
end
