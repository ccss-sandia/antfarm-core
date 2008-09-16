class TrafficController < ApplicationController
  active_scaffold :traffic do |config|
    config.label = 'Traffic'
  end
end
