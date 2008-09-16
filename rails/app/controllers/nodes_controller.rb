class NodesController < ApplicationController
  active_scaffold :node do |config|
    config.columns[:certainty_factor].label = 'Certainty Factor'
    config.create.columns = [:name, :device_type, :certainty_factor, :layer2_interfaces]
    config.list.columns = [:name, :device_type, :layer2_interfaces, :services, :operating_system]
    config.show.columns = [:name, :device_type, :certainty_factor, :layer2_interfaces]
    config.update.columns = [:name, :device_type, :certainty_factor, :layer2_interfaces]
  end
end
