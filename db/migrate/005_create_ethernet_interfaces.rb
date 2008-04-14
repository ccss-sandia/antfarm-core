# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

class CreateEthernetInterfaces < ActiveRecord::Migration
  def self.up
    create_table :ethernet_interfaces do |t|
      t.string :address, :null => false
    end
  end

  def self.down
    drop_table :ethernet_interfaces
  end
end
