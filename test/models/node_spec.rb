require 'test/spec_helper'

describe Antfarm::Model::Node, '#create' do
  it 'should fail if no certainty factor exists' do
    node = Antfarm::Model::Node.create :certainty_factor => nil
    node.valid?.should == false
    node.saved?.should == false
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    node = Antfarm::Model::Node.create :certainty_factor => 0.5
    node.certainty_factor.should == 0.5
    node = Antfarm::Model::Node.create :certainty_factor => -1.5
    node.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_FALSE
    node = Antfarm::Model::Node.create :certainty_factor => 1.5
    node.certainty_factor.should == Antfarm::Helpers::CF_PROVEN_TRUE
  end
end

describe Antfarm::Model::Node, '#save' do
  it 'should fail if no certainty factor exists' do
    node = Antfarm::Model::Node.create
    node.certainty_factor = nil
    node.valid?.should == false
    node.errors.length.should == 1
    node.certainty_factor.should != nil
  end

  it 'should clamp the certainty factor between the predefined PROVEN values' do
    node = Antfarm::Model::Node.create
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
end

describe Antfarm::Model::Node, '#destroy' do
  it 'should destroy any associated layer 2 interfaces' do
    iface = Antfarm::Model::Layer2Interface.create
    id = iface.id
    node = iface.node
    node.destroy
    Antfarm::Model::Layer2Interface.get(id).should == nil
  end
end
