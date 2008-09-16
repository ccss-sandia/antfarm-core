class ServicesController < ApplicationController
  active_scaffold :service do |config|
    config.list.columns = [:name, :protocol, :port, :certainty_factor, :node, :action]
  end
end
