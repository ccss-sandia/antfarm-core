# Node model for nodes table.
#
# Copyright::       Copyright (c) 2008 Sandia National Laboratories
# Original Author:: Bryan T. Richardson <btricha@sandia.gov>
# Derived From::    code written by Michael Berg <mjberg@sandia.gov>

# Node class that wraps the nodes table in the ANTFARM database.
#
# * has many layer 2 interfaces
# * has many layer 3 interfaces through layer 2 interfaces
class Node < ActiveRecord::Base
  has_many :layer2_interfaces
  has_many :layer3_interfaces, :through => :layer2_interfaces

  before_save :clamp_certainty_factor

  validates_presence_of :certainty_factor

  # Find and return the first node found with the given name.
  def self.node_named(name)
    unless name
      raise(ArgumentError, "nil argument supplied", caller)
    end

    node = self.find_all_by_name(name)

    case node.length
    when 0
      logger.warn("Node: did not find an existing node with given name.")
      return nil
    else
      logger.info("Node: found existing nodes with given name.")
      return node[0]
    end
  end

  # Find and return all the nodes found that are the given type.
  def self.nodes_of_device_type(device_type)
    unless device_type
      raise(ArgumentError, "nil argument supplied", caller)
    end

    nodes = self.find_all_by_device_type(device_type)

    case nodes.length
    when 0
      logger.warn("Node: did not find any existing nodes of given device type.")
      return nil
    else
      logger.info("Node: found existing nodes of given device type.")
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

