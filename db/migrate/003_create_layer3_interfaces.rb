# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

class CreateLayer3Interfaces < ActiveRecord::Migration
  def self.up
    create_table :layer3_interfaces do |t|
      t.float :certainty_factor, :null => false
      t.string :protocol
      t.references :layer2_interface, :null => false
      t.references :layer3_network, :null => false
    end
  end

  def self.down
    drop_table :layer3_interfaces
  end
end
