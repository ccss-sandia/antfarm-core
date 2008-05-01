# Traffic model that wraps the traffic table.
#
# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

# Traffic class that wraps the traffic table
# in the ANTFARM database.
#
# * belongs to a layer 3 interface (defined as source_layer3_interface)
# * belongs to a layer 3 interface (defined as target_layer3_interface)
class Traffic < ActiveRecord::Base
  set_table_name "traffic"

  belongs_to :source_layer3_interface, :class_name => "Layer3Interface", :foreign_key => "source_layer3_interface_id"
  belongs_to :target_layer3_interface, :class_name => "Layer3Interface", :foreign_key => "target_layer3_interface_id"
end

