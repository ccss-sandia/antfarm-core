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

# Required tests for the ANTFARM EthernetInterface model:
#
# Create
#
# Creating a model should fail if no address is present.
#
# Creating a model should fail if the address present
# doesn't match the correct format for a MAC address.
#
# Creating a model should also create a new associated layer two interface model
# if one is not supplied. If layer two interface information is supplied, the
# layer two interface model created should be initialized with the supplied
# information. If a layer two interface model is supplied, the model created
# should be associated with the supplied layer two interface model.
#
# Save
#
# Saving a model should require the presence of an ethernet
# address and the address provided should match the correct
# format for MAC addresses.

describe Antfarm::Model::EthernetInterface, '#create' do
  it 'should fail if no address exists' do
    iface = Antfarm::Model::EthernetInterface.create
    iface.valid?.should == false
    iface.saved?.should == false
  end

  it 'should fail if the address is not in MAC address format' do
    iface = Antfarm::Model::EthernetInterface.create :address => 'foo:bar'
    iface.valid?.should == false
    iface.saved?.should == false
  end

  it 'should create a new layer two interface' do
    count = Antfarm::Model::LayerTwoInterface.all.length
    iface = Antfarm::Model::EthernetInterface.new
    iface.address = '00:00:00:00:00:00'
    iface.save
    iface.layer_two_interface.should_not == nil
    Antfarm::Model::LayerTwoInterface.all.length.should == count + 1
    iface.layer_two_interface.should == Antfarm::Model::LayerTwoInterface.all.last
  end

  it 'should use a given certainty factor when creating a new layer two interface' do
    count = Antfarm::Model::LayerTwoInterface.all.length
    iface = Antfarm::Model::EthernetInterface.new
    iface.address = '00:00:00:00:00:00'
    iface.layer_two_interface = { :certainty_factor => 0.5 }
    iface.save
    iface.layer_two_interface.should_not == nil
    Antfarm::Model::LayerTwoInterface.all.length.should == count + 1
    iface.layer_two_interface.should == Antfarm::Model::LayerTwoInterface.all.last
    iface.layer_two_interface.certainty_factor.should == 0.5
  end

  it 'should use a given layer two interface' do
    count = Antfarm::Model::LayerTwoInterface.all.length
    l2_iface = Antfarm::Model::LayerTwoInterface.create
    Antfarm::Model::LayerTwoInterface.all.length.should == count + 1
    Antfarm::Model::LayerTwoInterface.all.last.should == l2_iface
    iface = Antfarm::Model::EthernetInterface.new
    iface.address = '00:00:00:00:00:00'
    iface.layer_two_interface = l2_iface
    iface.save
    iface.layer_two_interface.should_not == nil
    iface.layer_two_interface.should == l2_iface
  end

  it 'should not create a new layer 2 interface if invalid' do
    count = Antfarm::Model::LayerTwoInterface.all.length
    iface = Antfarm::Model::EthernetInterface.create

    iface.valid?.should == false
    Antfarm::Model::LayerTwoInterface.all.length.should == count
  end

  it 'should create a new layer 2 interface if valid' do
    count = Antfarm::Model::LayerTwoInterface.all.length
    iface = Antfarm::Model::EthernetInterface.create :address => '00:00:00:00:00:00'

    iface.valid?.should == true
    Antfarm::Model::LayerTwoInterface.all.length.should == count + 1
    iface.layer_two_interface.should == Antfarm::Model::LayerTwoInterface.all.last
  end
end
