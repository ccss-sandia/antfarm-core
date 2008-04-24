# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

class CreateTraffic < ActiveRecord::Migration
  def self.up
    create_table :traffic do |t|
      t.string  :description
      t.integer :port, :null => false, :default => 0
      t.string  :timestamp
      t.integer :source_layer3_interface_id, :null => false
      t.integer :target_layer3_interface_id, :null => false
    end
  end

  def self.down
    drop_table :traffic
  end
end
