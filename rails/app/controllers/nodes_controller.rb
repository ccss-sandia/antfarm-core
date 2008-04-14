require 'layer2_interface'
require 'node'

class NodesController < ApplicationController
  active_scaffold :node do |config|
    config.columns[:certainty_factor].label = 'Certainty Factor'
    config.create.columns = [:name, :type, :certainty_factor, :layer2_interfaces]
    config.list.columns = [:name, :type, :layer2_interfaces]
    config.show.columns = [:name, :type, :certainty_factor, :layer2_interfaces]
    config.update.columns = [:name, :type, :certainty_factor, :layer2_interfaces]
  end
end
