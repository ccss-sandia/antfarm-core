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

# Required tests for the ANTFARM IpNetwork model:
#
# Create
#
# Creating a model should fail if no address is present.
#
# Creating a model should fail if the address present
# doesn't match the correct format for an IP network.
#
# Creating a model should also create a new associated layer 3 network model
# if one is not supplied. If layer 3 network information is supplied, the
# layer 3 network model created should be initialized with the supplied
# information. If a layer 3 network model is supplied, the model created
# should be associated with the supplied layer 3 network model.
#
# Save
#
# Saving a model should require the presence of an ip
# network address and the address provided should match
# the correct format for an IP network.

describe Antfarm::Model::IpNetwork, '#create' do
  before(:each) do
    Antfarm::Model::IpNetwork.all.destroy
    Antfarm::Model::LayerThreeNetwork.all.destroy
  end

  it 'should fail if no address exists' do
    network = Antfarm::Model::IpNetwork.create
    network.valid?.should == false
    network.saved?.should == false
  end

  it 'should fail if the address is not in IP network format' do
    network = Antfarm::Model::IpNetwork.create :address => 'foo.bar'
    network.valid?.should == false
    network.saved?.should == false
  end

  it 'should create a new layer three network' do
    count   = Antfarm::Model::LayerThreeNetwork.all.length
    network = Antfarm::Model::IpNetwork.create :address => '192.168.101.0/24'
    network.layer_three_network.should_not == nil
    Antfarm::Model::LayerThreeNetwork.all.length.should == count + 1
    network.layer_three_network.should == Antfarm::Model::LayerThreeNetwork.all.last
  end

  it 'should use a given certainty factor when creating a new layer three network' do
    count   = Antfarm::Model::LayerThreeNetwork.all.length
    network = Antfarm::Model::IpNetwork.new
    network.address = '192.168.101.0/24'
    network.layer_three_network = { :certainty_factor => 0.5 }
    network.save
    network.valid?.should == true
    network.saved?.should == true
    network.layer_three_network.nil?.should == false
    network.layer_three_network.valid?.should == true
    network.layer_three_network.saved?.should == true
    Antfarm::Model::LayerThreeNetwork.all.length.should == count + 1
    network.layer_three_network.should == Antfarm::Model::LayerThreeNetwork.all.last
    network.layer_three_network.certainty_factor.should == 0.5
  end

  # TODO: would this EVER be necessary?! <scrapcoder>
  it 'should use a given layer three network' do
    count  = Antfarm::Model::LayerThreeNetwork.all.length
    l3_net = Antfarm::Model::LayerThreeNetwork.create
    Antfarm::Model::LayerThreeNetwork.all.length.should == count + 1
    Antfarm::Model::LayerThreeNetwork.all.last.should == l3_net
    network = Antfarm::Model::IpNetwork.new
    network.address = '192.168.101.0/24'
    network.layer_three_network = l3_net
    network.save
    network.layer_three_network.should_not == nil
    network.layer_three_network.should == l3_net
  end

  it 'should gobble up any networks that are sub networks of the newly created network' do
    network = Antfarm::Model::IpNetwork.create :address => '192.168.101.0/29'
    iface   = Antfarm::Model::LayerThreeInterface.create :layer_three_network => network.layer_three_network
    new_net = Antfarm::Model::IpNetwork.create :address => '192.168.101.0/16'
    Antfarm::Model::LayerThreeNetwork.get(network.layer_three_network.id).should == nil
    Antfarm::Model::IpNetwork.get(network.id).should == nil
    Antfarm::Model::LayerThreeInterface.get(iface.id).layer_three_network.should == new_net.layer_three_network
    new_net.layer_three_network.layer_three_interfaces.include?(iface).should == true
  end

  it 'should be marked as private if the given address is in private address space' do
    network = Antfarm::Model::IpNetwork.create :address => '192.168.101.0/29'
    network.valid?.should == true
    network.saved?.should == true
    network.private.should == true
  end
end
