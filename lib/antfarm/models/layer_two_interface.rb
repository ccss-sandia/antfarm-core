################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

module Antfarm
  module Model
    class LayerTwoInterface
      include DataMapper::Resource

      storage_names[:default] = 'layer_two_interfaces'

      property :id,               Serial
      property :certainty_factor, Float, :required => true, :default => 0.8
      property :media_type,       String
      property :custom,           String

#     has n,     :layer3_interfaces
#     has 1,     :ethernet_interface, :child_key => :id, :constraint => :destroy
      has 1,     :ethernet_interface, :constraint => :destroy
      belongs_to :node, :required => true

      validates_present :certainty_factor

      # Need to do this before validation
      # since :required => true is specified
      # on the node association above.
      before :valid?, :create_node
      before :save,   :clamp_certainty_factor
#     after  :save,   :destroy_orphaned_nodes # TODO: be sure to write test if used!

      #######
      private
      #######

      # If a hash is passed into the node variable,
      # parameters matching variables on the node
      # class will be used to create a new node object.
      def create_node
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] Layer2Interface#create_node'

        # Only create a new node if a node model
        # isn't already associated with this model.
        # This protects against new nodes being
        # created when one is already provided or
        # when this model is being saved rather
        # than created (since a node will be
        # automatically created and associated with
        # this model on creation).
        self.node ||= Antfarm::Model::Node.create
      end

      def clamp_certainty_factor
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] LayerTwoInterface#clamp_certainty_factor'
        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end

      def destroy_orphaned_nodes
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] LayerTwoInterface#destroy_orphaned_nodes'

        Node.all.each do |n|
          if n.layer2_interfaces.empty?
            Antfarm::Helpers.log :debug, "LayerTwoInterface - destroying orphaned node #{node}"
            n.destroy
          end
        end
      end
    end
  end
end
