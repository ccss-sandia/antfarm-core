module Antfarm
  module Models
    class Traffic
      include DataMapper::Resource

      property :id,   Serial
      property :port, Integer

      belongs_to :source, :class_name => 'Layer3Interface', :child_key => [:source_id]
      belongs_to :target, :class_name => 'Layer3Interface', :child_key => [:target_id]

      has_tags_on :tags
    end
  end
end
