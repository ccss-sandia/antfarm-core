# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 13) do

  create_table "actions", :force => true do |t|
    t.string "tool"
    t.string "description"
    t.string "start"
    t.string "end"
  end

  create_table "dns_entries", :force => true do |t|
    t.string "address"
    t.string "hostname"
  end

  create_table "ethernet_interfaces", :force => true do |t|
    t.string "address", :null => false
  end

  create_table "ip_interfaces", :force => true do |t|
    t.string "address", :null => false
  end

  create_table "ip_networks", :force => true do |t|
    t.string  "address",                               :null => false
    t.boolean "private",            :default => false, :null => false
    t.integer "private_network_id"
  end

  create_table "layer2_interfaces", :force => true do |t|
    t.float   "certainty_factor", :null => false
    t.string  "media_type"
    t.integer "node_id",          :null => false
  end

  create_table "layer3_interfaces", :force => true do |t|
    t.float   "certainty_factor",    :null => false
    t.string  "protocol"
    t.integer "layer2_interface_id", :null => false
    t.integer "layer3_network_id",   :null => false
  end

  create_table "layer3_networks", :force => true do |t|
    t.float  "certainty_factor", :null => false
    t.string "protocol"
  end

  create_table "nodes", :force => true do |t|
    t.float  "certainty_factor", :null => false
    t.string "name"
    t.string "device_type"
  end

  create_table "operating_systems", :force => true do |t|
    t.float   "certainty_factor", :null => false
    t.integer "node_id"
    t.integer "action_id"
    t.text    "fingerprint"
  end

  create_table "private_networks", :force => true do |t|
    t.string "description"
  end

  create_table "services", :force => true do |t|
    t.float   "certainty_factor", :null => false
    t.integer "node_id"
    t.integer "action_id"
    t.string  "protocol"
    t.integer "port"
    t.string  "name"
  end

  create_table "traffic", :force => true do |t|
    t.string  "description"
    t.integer "port",                       :default => 0, :null => false
    t.string  "timestamp"
    t.integer "source_layer3_interface_id",                :null => false
    t.integer "target_layer3_interface_id",                :null => false
  end

end
