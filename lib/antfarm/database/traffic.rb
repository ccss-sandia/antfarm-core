# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Original Author: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or (at
# your option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 

# Traffic class that wraps the traffic table
# in the ANTFARM database.
#
# * belongs to a layer 3 interface (defined as source_layer3_interface)
# * belongs to a layer 3 interface (defined as target_layer3_interface)
module Antfarm
  module Database
    class Traffic
      include DataMapper::Resource

      storage_names[:default] = 'traffic'

      property :id,          Serial
      property :source_id,   Integer, :null => false
      property :target_id,   Integer, :null => false
      property :description, String
      property :port,        Integer, :null => false, :default => 0
      property :timestamp,   String
      property :custom,      String

      belongs_to :source, :class_name => "Layer3Interface", :child_key => [:source_id]
      belongs_to :target, :class_name => "Layer3Interface", :child_key => [:target_id]
    end
  end
end
