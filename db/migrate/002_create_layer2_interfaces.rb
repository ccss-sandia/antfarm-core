# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

class CreateLayer2Interfaces < ActiveRecord::Migration
  def self.up
    create_table :layer2_interfaces do |t|
      t.float :certainty_factor, :null => false
      t.string :media_type
      t.references :node, :null => false
    end
  end

  def self.down
    drop_table :layer2_interfaces
  end
end
