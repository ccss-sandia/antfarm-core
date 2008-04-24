# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>

class Layer3Interface < ActiveRecord::Base
  has_many   :outbound_traffic, :class_name => "Traffic", :foreign_key => "source_layer3_interface_id"
  has_many   :inbound_traffic,  :class_name => "Traffic", :foreign_key => "target_layer3_interface_id"
  has_one    :ip_interface,                               :foreign_key => "id"
  belongs_to :layer2_interface
  belongs_to :layer3_network

  before_create :create_layer3_network
  before_create :create_layer2_interface
  before_save :clamp_certainty_factor

  # Added to make it possible to specify what to set for the media type and
  # either the node object or the node type for the Layer2Interface and the
  # protocol for the Layer3Network that will be associated with this interface.
  attr_writer :layer3_network_protocol, :layer2_interface_media_type, :node, :node_name, :node_device_type

  validates_presence_of :certainty_factor

  # Find the Layer3Interface with the given address.
  def self.interface_addressed(ip_addr_str)
    unless ip_addr_str
      raise(ArgumentError, "nil argument supplied", caller)
    end

    ip_ifs = IpInterface.find(:all)
    for ip_if in ip_ifs
      if Antfarm::IPAddrExt.new(ip_addr_str) == Antfarm::IPAddrExt.new(ip_if.address)
        return Layer3Interface.find(ip_if.id)
      end
    end

    return nil
  end

  # This is for ActiveScaffold
  def to_label
    return "#{id} -- #{ip_interface.address}" if ip_interface
    return "#{id} -- Generic Layer3 Interface"
  end

  def node
    return "#{layer2_interface.node.name}"
  end

  #######
  private
  #######

  def create_layer3_network
    unless self.layer3_network
      layer3_network = Layer3Network.new :certainty_factor => 0.75
      layer3_network.protocol = @layer3_network_protocol if @layer3_network_protocol
      if layer3_network.save
        logger.info("Layer3Interface: Created Layer 3 Network")
#       puts "Layer3Interface: Created Layer 3 Network"
      else
        logger.warn("Layer3Interface: Errors occured while creating Layer 3 Network")
#       puts "Layer3Interface: Errors occured while creating Layer 3 Network"
        layer3_network.errors.each_full do |msg|
          logger.warn(msg)
#         puts msg
        end
      end

      self.layer3_network = layer3_network
    end
  end

  def create_layer2_interface
    unless self.layer2_interface
      layer2_interface = Layer2Interface.new :certainty_factor => 0.75
      layer2_interface.media_type = @layer2_interface_media_type if @layer2_interface_media_type
      layer2_interface.node = @node if @node
      layer2_interface.node_name = @node_name if @node_name
      layer2_interface.node_device_type = @node_device_type if @node_device_type
      if layer2_interface.save
        logger.info("Layer3Interface: Created Layer 2 Interface")
#       puts "Layer3Interface: Created Layer 2 Interface"
      else
        logger.warn("Layer3Interface: Errors occured while creating Layer 2 Interface")
#       puts "Layer3Interface: Errors occured while creating Layer 2 Interface"
        layer2_interface.errors.each_full do |msg|
          logger.warn(msg)
#         puts msg
        end
      end

      self.layer2_interface = layer2_interface
    end
  end

  def clamp_certainty_factor
    self.certainty_factor = Antfarm.clamp(self.certainty_factor)
  end
end

