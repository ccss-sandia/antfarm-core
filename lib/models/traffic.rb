# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

class Traffic < ActiveRecord::Base
  set_table_name "traffic"

  belongs_to :source_layer3_interface, :class_name => "Layer3Interface", :foreign_key => "source_layer3_interface_id"
  belongs_to :target_layer3_interface, :class_name => "Layer3Interface", :foreign_key => "target_layer3_interface_id"
 
  # This is necessary because the default column name for use with
  # single table inheritance is "type", but we use the column name
  # "type" to describe the type of traffic this is.
  set_inheritance_column :table_type

  def self.add(from_layer3_interface, to_layer3_interface, port = nil, description = nil)
    port = 0 if port.nil?
    conn = self.connection_exists?(from_layer3_interface, to_layer3_interface, port)
    if conn
      Traffic.update(conn.id, { :count => conn.count + 1 })
      logger.info("Traffic: updated existing connection. Count is now #{conn.count + 1}.")
#     puts "Traffic: updated existing connection. Count is now #{conn.count + 1}."
    else
      conn = Traffic.new
      conn.description = description unless description.nil?
      conn.from_layer3_interface = from_layer3_interface
      conn.to_layer3_interface = to_layer3_interface
      conn.port = port
      conn.count = 1

      logger.info("Traffic: created new connection.")
#     puts "Traffic: created new connection."
      
      unless conn.save
        logger.warn("Traffic: Errors occured while creating Traffic")
        conn.errors.each_full do |msg|
          logger.warn(msg)
#         puts msg
        end
      end
    end
  end

  #########
  protected
  #########

  def self.connection_exists?(from_layer3_interface, to_layer3_interface, port)
    conn = Traffic.find(:all, :conditions => [ "from_layer3_interface_id = ? AND to_layer3_interface_id = ? AND port = ?", from_layer3_interface, to_layer3_interface, port ])

    case conn.length
    when 0
      logger.warn("Traffic: did not find existing connection.")
#     puts "Traffic: did not find existing connection."
      return nil
    when 1
      logger.info("Traffic: found existing connection.")
#     puts "Traffic: found existing connection."
      return conn[0]
    else
      raise(StandardError, "returned more than 1 connection", caller)
    end
  end
end
