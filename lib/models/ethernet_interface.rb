# Ethernet Interface model for ethernet_interfaces table.
#
# Copyright::       Copyright (c) 2008 Sandia National Laboratories
# Original Author:: Bryan T. Richardson <btricha@sandia.gov>
# Derived From::    code written by Michael Berg <mjberg@sandia.gov>

# EthernetInterface class that wraps the ethernet_interfaces
# table in the ANTFARM database.
#
# * belongs to a layer 2 interface
#
# The node_name and node_device_type attributes are only applicable
# when an existing node is not specified.
#
# The node and layer2_interface_media_type attributes are only
# applicable when an existing layer 2 interface is not specified.
class EthernetInterface < ActiveRecord::Base
  belongs_to :layer2_interface, :foreign_key => "id"

  before_create :create_layer2_interface

  # Media type of the layer 2 interface automatically
  # creted for this ethernet interface.
  attr_writer :layer2_interface_media_type

  # Existing node the layer 2 interface automatically
  # created for this ethernet interface should belong to.
  attr_writer :node

  # Name of the node automatically created by the layer 2
  # interface created for this ethernet interface.
  attr_writer :node_name

  # Device type of the node automatically created by the
  # layer 2 interface created for this ethernet interface.
  attr_writer :node_device_type

  # This ensures that the MAC address entered is of the right format.  It is called
  # *before* the before_create method below is called, which keeps the Layer2Interface
  # from being created if the address format is not valid.
  validates_format_of :address, :with => /^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$/i,
                                :on => :save,
                                :message => "invalid MAC address format"

  validates_presence_of :address

  # This is for ActiveScaffold
  def to_label #:nodoc:
    return address
  end

  #######
  private
  #######

  def create_layer2_interface
    unless self.layer2_interface
      layer2_interface = Layer2Interface.new :certainty_factor => 0.75
      layer2_interface.media_type = @layer2_interface_media_type if @layer2_interface_media_type
      layer2_interface.node = @node if @node
      layer2_interface.node_name = @node_name if @node_name
      layer2_interface.node_device_type = @node_device_type if @node_device_type
      if layer2_interface.save
        logger.info("EthernetInterface: Create Layer 2 Interface")
      else
        logger.warn("EthernetInterface: Errors occured while creating Layer 2 Interface")
        layer2_interface.errors.each_full do |msg|
          logger.warn(msg)
        end
      end

      self.layer2_interface = layer2_interface
    end
  end
end

