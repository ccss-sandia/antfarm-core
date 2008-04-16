# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>

require 'antfarm'
require 'layer2_interface'
require 'layer3_interface'

class Node < ActiveRecord::Base
  has_many :layer2_interfaces
  has_many :layer3_interfaces, :through => :layer2_interfaces

  # This is necessary because the default column name for use with
  # single table inheritance is "type", but we use the column name
  # "type" to describe the type of node this is.
  set_inheritance_column :table_type

  before_save :clamp_certainty_factor

  validates_presence_of :certainty_factor

  def self.node_named(name)
    unless name
      raise(ArgumentError, "nil argument supplied", caller)
    end

    node = self.find(:all, :conditions => [ "name = ?", name ])

    case node.length
    when 0
      logger.warn("Node: did not find an existing node with given name.")
#     puts "Node: did not find an existing node with given name."
      return nil
    else
      logger.info("Node: found existing nodes with given name.")
#     puts "Node: found existing node with given name."
      return node[0]
    end
  end

  def self.nodes_of_type(type)
    unless type
      raise(ArgumentError, "nil argument supplied", caller)
    end

    nodes = self.find(:all, :conditions => [ "type = ?", type ])

    case nodes.length
    when 0
      logger.warn("Node: did not find any existing nodes of given type.")
#     puts "Node: did not find any existing nodes of given type."
      return nil
    else
      logger.info("Node: found existing nodes of given type.")
#     puts "Node: found existing nodes of given type."
      return nodes
    end
  end

  #######
  private
  #######

  def clamp_certainty_factor
    self.certainty_factor = Antfarm.clamp(self.certainty_factor)
  end
end

