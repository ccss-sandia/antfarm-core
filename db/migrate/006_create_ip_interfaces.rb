# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

class CreateIpInterfaces < ActiveRecord::Migration
  def self.up
    create_table :ip_interfaces do |t|
      t.string :address, :null => false
    end
  end

  def self.down
    drop_table :ip_interfaces
  end
end
