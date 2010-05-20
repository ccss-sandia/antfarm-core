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
end
