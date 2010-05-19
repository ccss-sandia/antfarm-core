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

# TODO: change variable names
# Mass substitution of Node to Layer2Interface
# led to variable names not being correct for
# clamping tests...

describe Antfarm::Model::LayerTwoInterface, '#create' do
  it 'should fail if no certainty factor exists' do
    iface = Antfarm::Model::LayerTwoInterface.create :certainty_factor => nil
    iface.valid?.should == false
    iface.saved?.should == false
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    node = Antfarm::Model::LayerTwoInterface.create :certainty_factor => 0.5
    node.certainty_factor.should == 0.5
    node = Antfarm::Model::LayerTwoInterface.create :certainty_factor => -1.5
    node.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_FALSE
    node = Antfarm::Model::LayerTwoInterface.create :certainty_factor => 1.5
    node.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_TRUE
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
    node = Antfarm::Model::Node.create
    count = Antfarm::Model::Node.all.length
    iface = Antfarm::Model::LayerTwoInterface.create :node => node
    iface.node.should_not == nil
    Antfarm::Model::Node.all.length.should == count
    iface.node.should == node
  end
end

describe Antfarm::Model::LayerTwoInterface, '#save' do
  it 'should fail if no certainty factor exists' do
    node = Antfarm::Model::LayerTwoInterface.create
    node.certainty_factor = nil
    node.valid?.should == false
    node.errors.length.should == 1
    node.certainty_factor.should != nil
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    node = Antfarm::Model::LayerTwoInterface.create
    node.saved?.should == true
    node.certainty_factor = 0.5
    node.save
    node.certainty_factor.should == 0.5
    node.certainty_factor = -1.5
    node.save
    node.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_FALSE
    node.certainty_factor = 1.5
    node.save
    node.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_TRUE
  end

  it 'should not create a new node model' do
    iface = Antfarm::Model::LayerTwoInterface.create
    node_id = iface.node.id
    iface.certainty_factor = 0.5
    iface.save
    iface.certainty_factor.should == 0.5
    iface.node.id.should == node_id
  end
end

describe Antfarm::Model::LayerTwoInterface, '#destroy' do
  # TODO: figure out why this is failing
  # For some reason, calling 'l2_iface.ethernet_interface'
  # below leads to a 'no destroy method for nil object', yet
  # when something similar is ran in an irb console it works
  # just fine... :(
  #
  # 05/18/2010 - It's because the ethernet interface isn't being
  # associated with the layer 2 interface via the 'id' column
  # like it was when we were using ActiveRecord. See the
  # EthernetInterface model for more details.
  it 'should also destroy any associated ethernet interfaces' do
    iface = Antfarm::Model::EthernetInterface.create :address => '00:00:00:00:00:00'
    id    = iface.id
    count = Antfarm::Model::EthernetInterface.all.length

    l2_iface = iface.layer_two_interface
    l2_iface.destroy

    l2_iface.destroyed?.should == true
    Antfarm::Model::EthernetInterface.get(id).should == nil
    Antfarm::Model::EthernetInterface.all.length.should == count - 1
  end
end
