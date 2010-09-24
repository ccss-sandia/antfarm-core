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

# Required tests for the ANTFARM Layer2Interface model:
#
# Create
#
# Creating a model should fail if no certainty factor is present (this doesn't
# mean a default value can't be set).
#
# Creating a model should fail if the certainty factor present isn't between
# the library-defined PROVEN values.
#
# Creating a model should also create a new associated node model if one is not
# supplied. If node information is supplied, the node model created should be
# initialized with the supplied information. If a node model is supplied, the
# model created should be associated with the supplied node model.
#
# Save
#
# Saving a model should fail if no certainty factor is present.
#
# Saving a model should fail if the certainty factor present isn't between
# the library-defined PROVEN values.
#
# Saving a model should not create a new node model.
#
# Destroy
#
# TODO: add the '#destroy' tests once ethernet interface and layer 3 interface
# models are added.
#
# Destoying a model should also destroy any and all ethernet interface and
# layer 3 interface models associated with the model.

describe Antfarm::Model::LayerTwoInterface, '#create' do
  it 'should fail if no certainty factor exists' do
    iface = Antfarm::Model::LayerTwoInterface.create :certainty_factor => nil
    iface.valid?.should == false
    iface.saved?.should == false
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    iface = Antfarm::Model::LayerTwoInterface.create :certainty_factor => 0.5
    iface.certainty_factor.should == 0.5
    iface = Antfarm::Model::LayerTwoInterface.create :certainty_factor => -1.5
    iface.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_FALSE
    iface = Antfarm::Model::LayerTwoInterface.create :certainty_factor => 1.5
    iface.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_TRUE
  end

  it 'should create a new node' do
    count = Antfarm::Model::Node.all.length
    iface = Antfarm::Model::LayerTwoInterface.create
    iface.node.should_not == nil
    Antfarm::Model::Node.all.length.should == count + 1
    iface.node.should == Antfarm::Model::Node.all.last
  end

  it 'should use a given node name when creating a new node' do
    count = Antfarm::Model::Node.all.length
    iface = Antfarm::Model::LayerTwoInterface.create :node => { :name => 'Test Me' }
    iface.node.should_not == nil
    Antfarm::Model::Node.all.length.should == count + 1
    iface.node.should == Antfarm::Model::Node.all.last
    iface.node.name.should == 'Test Me'
  end

  it 'should use a given node' do
    node  = Antfarm::Model::Node.create
    count = Antfarm::Model::Node.all.length
    iface = Antfarm::Model::LayerTwoInterface.create :node => node
    iface.node.should_not == nil
    Antfarm::Model::Node.all.length.should == count
    iface.node.should == node
  end
end

describe Antfarm::Model::LayerTwoInterface, '#save' do
  it 'should fail if no certainty factor exists' do
    iface = Antfarm::Model::LayerTwoInterface.create
    iface.certainty_factor = nil
    iface.valid?.should == false
    iface.errors.length.should == 1
    iface.certainty_factor.should != nil
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    iface = Antfarm::Model::LayerTwoInterface.create
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

  it 'should not create a new node model' do
    iface = Antfarm::Model::LayerTwoInterface.create
    id    = iface.node.id
    iface.certainty_factor = 0.5
    iface.save
    iface.certainty_factor.should == 0.5
    iface.node.id.should == id
  end
end

describe Antfarm::Model::LayerTwoInterface, '#destroy' do
  it 'should also destroy any associated ethernet interfaces' do
    iface    = Antfarm::Model::EthernetInterface.create :address => '00:00:00:00:00:00'
    id       = iface.id
    count    = Antfarm::Model::EthernetInterface.all.length
    l2_iface = iface.layer_two_interface
    l2_iface.destroy
    l2_iface.destroyed?.should == true
    Antfarm::Model::EthernetInterface.get(id).should == nil
    Antfarm::Model::EthernetInterface.all.length.should == count - 1
  end
end
