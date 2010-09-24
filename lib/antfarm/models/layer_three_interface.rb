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
    class LayerThreeInterface
      include DataMapper::Resource

      storage_names[:default] = 'layer_three_interfaces'

      property :id,               Serial
      property :certainty_factor, Float, :required => true, :default => 0.8
      property :protocol,         String
      property :custom,           String

      belongs_to :layer_two_interface, :required => true
      belongs_to :layer_three_network, :required => true

      validates_present :certainty_factor

      # Need to do this before validation since
      # :required => true is specified on the
      # layer 2 interface association above.
      #
      # Note that we do NOT automatically create
      # a layer 3 network on creation. That should
      # ALWAYS be provided to this model by the
      # IP interface model when it's being created.
      before :valid?, :create_layer_two_interface
      before :save,   :clamp_certainty_factor

      #######
      private
      #######

      # If a hash is passed into the layer 2 interface variable,
      # parameters matching variables on the layer 2 interface
      # class will be used to create a new layer 2 interface object.
      def create_layer_two_interface
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] LayerThreeInterface#create_layer_two_interface'

        # Only create a new layer 2 interface if a
        # layer 2 interface model isn't already
        # associated with this model. This protects
        # against new layer 2 interfaces being
        # created when one is already provided or
        # when this model is being saved rather
        # than created (since a layer 2 interface
        # will be automatically created and
        # associated with this model on creation).
        self.layer_two_interface ||= Antfarm::Model::LayerTwoInterface.create
      end

      def clamp_certainty_factor
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] LayerThreeInterface#clamp_certainty_factor'
        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end
    end
  end
end
