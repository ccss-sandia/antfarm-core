# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.float :certainty_factor, :null => false
      t.string :name
      t.string :type
    end
  end

  def self.down
    drop_table :nodes
  end
end
