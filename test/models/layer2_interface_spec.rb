require 'test/spec_helper'

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
# Saving a model should not modify any information on any models associated
# with the model.
#
# Destroy
#
# Destoying a model should also destroy any and all ethernet interface and
# layer 3 interface models associated with the model.

# TODO: change variable names
# Mass substitution of Node to Layer2Interface
# led to variable names not being correct for
# clamping tests...

describe Antfarm::Model::Layer2Interface, '#create' do
  it 'should fail if no certainty factor exists' do
    iface = Antfarm::Model::Layer2Interface.create :certainty_factor => nil
    iface.valid?.should == false
    iface.saved?.should == false
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    node = Antfarm::Model::Layer2Interface.create :certainty_factor => 0.5
    node.certainty_factor.should == 0.5
    node = Antfarm::Model::Layer2Interface.create :certainty_factor => -1.5
    node.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_FALSE
    node = Antfarm::Model::Layer2Interface.create :certainty_factor => 1.5
    node.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_TRUE
  end

  it 'should create a new node' do
    count = Antfarm::Model::Node.all.length
    iface = Antfarm::Model::Layer2Interface.create
    iface.node.should_not == nil
    Antfarm::Model::Node.all.length.should == count + 1
    iface.node.should == Antfarm::Model::Node.all.last
  end

  it 'should use a given node name when creating a new node' do
    count = Antfarm::Model::Node.all.length
    iface = Antfarm::Model::Layer2Interface.create :node => { :name => 'Test Me' }
    iface.node.should_not == nil
    Antfarm::Model::Node.all.length.should == count + 1
    iface.node.should == Antfarm::Model::Node.all.last
    iface.node.name.should == 'Test Me'
  end

  it 'should use a given node' do
    node = Antfarm::Model::Node.create
    count = Antfarm::Model::Node.all.length
    iface = Antfarm::Model::Layer2Interface.create :node => node
    iface.node.should_not == nil
    Antfarm::Model::Node.all.length.should == count
    iface.node.should == node
  end
end

describe Antfarm::Model::Layer2Interface, '#save' do
  it 'should fail if no certainty factor exists' do
    node = Antfarm::Model::Layer2Interface.create
    node.certainty_factor = nil
    node.valid?.should == false
    node.errors.length.should == 1
    node.certainty_factor.should != nil
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    node = Antfarm::Model::Layer2Interface.create
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

  it 'should not update the associated node' do
  end
end
