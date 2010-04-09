require 'test/spec_helper'

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
