# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>

class Layer2Interface < ActiveRecord::Base
  has_many   :layer3_interfaces
  has_one    :ethernet_interface, :foreign_key => "id"
  belongs_to :node

  before_create :create_node
  before_save :clamp_certainty_factor

  # Added to make it possible to specify what to set for
  # the node type when the node is created automatically
  # by this interface.
  attr_writer :node_name, :node_type

  validates_presence_of :certainty_factor

  def self.interface_addressed(mac_addr_str)
    unless mac_addr_str
      raise(ArgumentError, "nil argument supplied", caller)
    end

    eth_ifs = EthernetInterface.find(:all)
    for eth_if in eth_ifs
      if mac_addr_str == eth_if.address
        return Layer2Interface.find(eth_if.id)
      end
    end

    return nil
  end

  # This is for ActiveScaffold
  def to_label
    return "#{id} -- #{ethernet_interface.address}" if ethernet_interface
    return "#{id} -- Generic Layer2 Interface"
  end

  #######
  private
  #######

  def create_node
    unless self.node
      node = Node.new :certainty_factor => 0.75
      node.name = @node_name if @node_name
      node.type = @node_type if @node_type
      if node.save
        logger.info("Layer2Interface: Created Node")
#       puts "Layer2Interface: Created Node"
      else
        logger.warn("Layer2Interface: Errors occured while creating Node")
#       puts "Layer2Interface: Errors occured while creating Node"
        node.errors.each_full do |msg|
          logger.warn(msg)
#         puts msg
        end
      end

      self.node = node
    end
  end

  def clamp_certainty_factor
    self.certainty_factor = Antfarm.clamp(self.certainty_factor)
  end
end

