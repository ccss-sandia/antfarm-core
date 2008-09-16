class ActionsController < ApplicationController
  active_scaffold :action do |config|
    config.list.columns = [:tool, :description, :start, :end]
  end
end
