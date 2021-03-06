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

# Required tests for the ANTFARM Layer3Network model:
#
# Create
#
# Creating a model should fail if no certainty factor is present (this doesn't
# mean a default value can't be set).
#
# Creating a model should fail if the certainty factor present isn't between
# the library-defined PROVEN values.
#
# Save
#
# Saving a model should fail if no certainty factor is present.
#
# Saving a model should fail if the certainty factor present isn't between
# the library-defined PROVEN values.
#
# Destroy
#
# Destoying a model should also destroy any and all layer 3 interface and IP
# network models associated with the model.
#
# Search
#
# If an IP network associated with a layer 3 network contains an IP address
# supplied, the layer 3 network should be returned. Otherwise, a new IP network
# should be created (which will automatically cause a new layer 3 network to be
# created) and the associated layer 3 network should be returned.

describe Antfarm::Model::LayerThreeNetwork, '#create' do
  it 'should fail if no certainty factor exists' do
    iface = Antfarm::Model::LayerThreeNetwork.create :certainty_factor => nil
    iface.valid?.should == false
    iface.saved?.should == false
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    iface = Antfarm::Model::LayerThreeNetwork.create :certainty_factor => 0.5
    iface.certainty_factor.should == 0.5
    iface = Antfarm::Model::LayerThreeNetwork.create :certainty_factor => -1.5
    iface.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_FALSE
    iface = Antfarm::Model::LayerThreeNetwork.create :certainty_factor => 1.5
    iface.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_TRUE
  end
end

describe Antfarm::Model::LayerThreeNetwork, '#save' do
  it 'should fail if no certainty factor exists' do
    iface = Antfarm::Model::LayerThreeNetwork.create
    iface.certainty_factor = nil
    iface.valid?.should == false
    iface.errors.length.should == 1
    iface.certainty_factor.should != nil
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    iface = Antfarm::Model::LayerThreeNetwork.create
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
end

describe Antfarm::Model::LayerThreeNetwork, '#search' do
  before(:each) do
    Antfarm::Model::LayerThreeNetwork.all.destroy
    Antfarm::Model::IpNetwork.all.destroy
  end

  it 'should return any networks that are sub networks of a given network' do
    network = Antfarm::Model::IpNetwork.create :address => '192.168.101.0/29'
    subs    = Antfarm::Model::LayerThreeNetwork.networks_contained_within('192.168.101.0/24')
    subs.length.should == 1
    subs.first.ip_network.address.should == '192.168.101.0/29'
  end

  it 'should not return any networks that are not sub networks of a given network' do
    network = Antfarm::Model::IpNetwork.create :address => '192.168.101.0/16'
    subs    = Antfarm::Model::LayerThreeNetwork.networks_contained_within('192.168.101.0/24')
    subs.each { |s| puts s.ip_network.address }
    subs.empty?.should == true
  end

  it 'should return the network a given network is the sub network of, if one exists' do
    network = Antfarm::Model::IpNetwork.create :address => '192.168.101.0/16'
    Antfarm::Model::LayerThreeNetwork.network_containing('192.168.101.0/29').ip_network.address.should == '192.168.101.0/16'
    Antfarm::Model::LayerThreeNetwork.network_containing('10.0.0.1/16').nil?.should == true
  end

  it 'should return the network with the given address' do
    network = Antfarm::Model::IpNetwork.create :address => '192.168.101.0/16'
    Antfarm::Model::LayerThreeNetwork.network_addressed('192.168.101.0/16').should == network.layer_three_network
    # See documentation for this method in lib/antfarm/models/LayerThreeNetwork.rb
    # to understand why this test works.
    Antfarm::Model::LayerThreeNetwork.network_containing('192.168.101.0/29').should == network.layer_three_network
  end
end
