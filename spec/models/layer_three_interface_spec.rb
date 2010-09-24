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

require 'spec/spec_helper'

# Required tests for the ANTFARM Layer3Interface model:
#
# Create
#
# Creating a model should fail if no certainty factor is present (this doesn't
# mean a default value can't be set).
#
# Creating a model should fail if the certainty factor present isn't between
# the library-defined PROVEN values.
#
# Creating a model should also create a new associated layer 2 interface model
# if one is not supplied. If layer 2 interface information is supplied, the
# layer 2 interface model created should be initialized with the supplied
# information. If a layer 2 interface model is supplied, the model created
# should be associated with the supplied layer 2 interface model.
#
# Creating a model should also create a new associated layer 3 network model
# if one is not supplied. If layer 3 network information is supplied, the
# layer 3 network model created should be initialized with the supplied
# information. If a layer 3 network model is supplied, the model created
# should be associated with the supplied layer 3 network model.
#
# Note that in all cases, the layer 3 network model should be supplied to the
# layer 3 interface when it's being created (see notes on IpInterface to
# understand why).
#
# Save
#
# Saving a model should fail if no certainty factor is present.
#
# Saving a model should fail if the certainty factor present isn't between
# the library-defined PROVEN values.
#
# Saving a model should not modify any information on any models associated
# with the model.
#
# Destroy
#
# Destoying a model should also destroy any and all IP interface models
# associated with the model.

describe Antfarm::Model::LayerThreeInterface, '#create' do
  it 'should fail if no certainty factor exists' do
    iface = Antfarm::Model::LayerThreeInterface.new
    iface.certainty_factor = nil
    iface.layer_three_network = Antfarm::Model::LayerThreeNetwork.create
    iface.save
    iface.valid?.should == false
    iface.saved?.should == false
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    iface = Antfarm::Model::LayerThreeInterface.new
    iface.certainty_factor = 0.5
    iface.layer_three_network = Antfarm::Model::LayerThreeNetwork.create
    iface.save
    iface.valid?.should == true
    iface.saved?.should == true
    iface.certainty_factor.should == 0.5

    iface = Antfarm::Model::LayerThreeInterface.new
    iface.certainty_factor = -1.5
    iface.layer_three_network = Antfarm::Model::LayerThreeNetwork.create
    iface.save
    iface.valid?.should == true
    iface.saved?.should == true
    iface.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_FALSE

    iface = Antfarm::Model::LayerThreeInterface.new
    iface.certainty_factor = 1.5
    iface.layer_three_network = Antfarm::Model::LayerThreeNetwork.create
    iface.save
    iface.valid?.should == true
    iface.saved?.should == true
    iface.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_TRUE
  end

  it 'should create a new layer 2 interface' do
    count = Antfarm::Model::LayerTwoInterface.all.length
    iface = Antfarm::Model::LayerThreeInterface.create
    iface.layer_two_interface.should_not == nil
    Antfarm::Model::LayerTwoInterface.all.length.should == count + 1
    iface.layer_two_interface.should == Antfarm::Model::LayerTwoInterface.all.last
  end

  it 'should use a given layer 2 interface' do
    l2_iface = Antfarm::Model::LayerTwoInterface.create
    count    = Antfarm::Model::LayerTwoInterface.all.length
    l3_iface = Antfarm::Model::LayerThreeInterface.create :layer_two_interface => l2_iface
    l3_iface.layer_two_interface.should_not == nil
    Antfarm::Model::LayerTwoInterface.all.length.should == count
    l3_iface.layer_two_interface.should == l2_iface
  end
end

describe Antfarm::Model::LayerThreeInterface, '#save' do
  it 'should fail if no certainty factor exists' do
    iface = Antfarm::Model::LayerThreeInterface.new
    iface.layer_three_network = Antfarm::Model::LayerThreeNetwork.create
    iface.save
    iface.valid?.should == true
    iface.saved?.should == true

    iface.certainty_factor = nil
    iface.valid?.should == false
    iface.errors.length.should == 1
    iface.certainty_factor.should != nil
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    iface = Antfarm::Model::LayerThreeInterface.new
    iface.layer_three_network = Antfarm::Model::LayerThreeNetwork.create
    iface.save
    iface.valid?.should == true
    iface.saved?.should == true

    iface.certainty_factor = 0.5
    iface.save
    iface.certainty_factor.should == 0.5

    iface.certainty_factor = -1.5
    iface.save
    iface.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_FALSE

    iface.certainty_factor = 1.5
    iface.save
    iface.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_TRUE
  end

  it 'should not create a new layer 2 interface model' do
    iface = Antfarm::Model::LayerThreeInterface.new
    iface.layer_three_network = Antfarm::Model::LayerThreeNetwork.create
    iface.save
    iface.valid?.should == true
    iface.saved?.should == true

    id = iface.layer_two_interface.id
    iface.certainty_factor = 0.5
    iface.save
    iface.certainty_factor.should == 0.5
    iface.layer_two_interface.id.should == id
  end
end
