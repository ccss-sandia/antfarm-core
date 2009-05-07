# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Original Author: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>
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

module Antfarm
  module Database
    class Service
      include DataMapper::Resource

      storage_names[:default] = 'services'

      property :id,               Serial
      property :node_id,          Integer
      property :action_id,        Integer
      property :certainty_factor, Float, :null => false
      property :protocol,         String
      property :port,             Integer
      property :name,             String
      property :custom,           String

      belongs_to :action
      belongs_to :node
    end
  end
end
