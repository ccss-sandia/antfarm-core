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
    class EthernetInterface
      include DataMapper::Resource

      storage_names[:default] = 'ethernet_interfaces'

      property :id,      Serial
      property :address, String, :required => true
      property :custom,  String

      # See the IpInterface model for an explanation of why we're doing this.
      property :layer_two_interface_id, Integer, :required => true, :auto_validation => false

      belongs_to :layer_two_interface #, :required => true, :auto_validation => false

      before :create, :create_layer_two_interface

      # This ensures that the MAC address entered
      validates_format :address, :with => %r{\A([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}\z},
                                 :message => 'invalid MAC address format'

      #######
      private
      #######

      # If a hash is passed into the layer2_interface
      # variable, parameters matching variables on the
      # layer 2 interface class will be used to create
      # a new layer 2 interface object. This also works
      # for nested hashes - i.e. if the hash passed into
      # the layer2_interface variable contains a 'node'
      # key that has a hash as a value, parameters in
      # that hash that match variables on the node class
      # will be used to create the node created by the
      # layer 2 interface. w00t!
      def create_layer_two_interface
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] EthernetInterface#create_layer_two_interface'

        # Only create a new layer 2 interface if
        # a layer 2 interface  model isn't already
        # associated with this model. This protects
        # against new layer 2 interfaces being
        # created when one is already provided or
        # when this model is being saved rather
        # than created (since a layer 2 interface
        # will be automatically created and associated
        # with this model on creation).
        self.layer_two_interface ||= Antfarm::Model::LayerTwoInterface.create
      end
    end
  end
end
