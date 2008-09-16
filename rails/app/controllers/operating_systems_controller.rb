class OperatingSystemsController < ApplicationController
  active_scaffold :operating_system do |config|
    config.list.columns = [:fingerprint, :certainty_factor, :node, :action]
  end
end
