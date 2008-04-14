# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

class CreateIpNetworks < ActiveRecord::Migration
  def self.up
    create_table :ip_networks do |t|
      t.string :address, :null => false
      t.boolean :private, :null => false, :default => false
      t.references :private_network
    end
  end

  def self.down
    drop_table :ip_networks
  end
end
