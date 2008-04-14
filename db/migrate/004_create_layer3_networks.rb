# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

class CreateLayer3Networks < ActiveRecord::Migration
  def self.up
    create_table :layer3_networks do |t|
      t.float :certainty_factor, :null => false
      t.string :protocol
    end
  end

  def self.down
    drop_table :layer3_networks
  end
end
