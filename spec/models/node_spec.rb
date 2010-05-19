require 'spec/spec_helper'

# Required tests for the ANTFARM Node model:
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
# Destoying a model should also destroy any and all layer 2 interface models
# associated with the model.

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
    iface = Antfarm::Model::LayerTwoInterface.create
    id    = iface.id
    count = Antfarm::Model::LayerTwoInterface.all.length
    iface.node.destroy
    iface.node.destroyed?.should == true
    Antfarm::Model::LayerTwoInterface.get(id).should == nil
    Antfarm::Model::LayerTwoInterface.all.length.should == count - 1
  end
end
