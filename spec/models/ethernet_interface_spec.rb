require 'test/spec_helper'

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
# The failure of a model being created should NOT stop the creation
# of a layer two interface model. TODO: what?! Why not? <scrapcoder>
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
end
