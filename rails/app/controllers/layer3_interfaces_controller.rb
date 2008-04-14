class Layer3InterfacesController < ApplicationController
  active_scaffold :layer3_interface do |config|
    config.columns << :node
    config.list.columns << :node
  end
end
