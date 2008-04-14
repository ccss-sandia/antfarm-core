# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

class CreatePrivateNetworks < ActiveRecord::Migration
  def self.up
    create_table :private_networks do |t|
      t.string :description
    end
  end

  def self.down
    drop_table :private_networks
  end
end
