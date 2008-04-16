# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>

require 'layer2_interface'

class EthernetInterface < ActiveRecord::Base
  belongs_to :layer2_interface, :foreign_key => "id"

  before_create :create_layer2_interface

  # Added to make it possible to specify what to set for the media type and 
  # either the node object or the node type for the Layer2Interface that
  # will be associated with this interface.
  attr_writer :layer2_interface_media_type, :node, :node_name, :node_type

  # This ensures that the MAC address entered is of the right format.  It is called
  # *before* the before_create method below is called, which keeps the Layer2Interface
  # from being created if the address format is not valid.
  validates_format_of :address, :with => /^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$/i,
                                :on => :save,
                                :message => "invalid MAC address format"

  validates_presence_of :address

  # This is for ActiveScaffold
  def to_label
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
      layer2_interface.node_type = @node_type if @node_type
      if layer2_interface.save
        logger.info("EthernetInterface: Create Layer 2 Interface")
#       puts "EthernetInterface: Create Layer 2 Interface"
      else
        logger.warn("EthernetInterface: Errors occured while creating Layer 2 Interface")
#       puts "EthernetInterface: Errors occured while creating Layer 2 Interface"
        layer2_interface.errors.each_full do |msg|
          logger.warn(msg)
#         puts msg
        end
      end

      self.layer2_interface = layer2_interface
    end
  end
end

