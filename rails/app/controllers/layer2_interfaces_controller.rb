class Layer2InterfacesController < ApplicationController
  active_scaffold :layer2_interface do |config|
    config.columns[:certainty_factor].label = 'Certainty Factor'
    config.columns[:media_type].label = 'Media Type'
  end
end
