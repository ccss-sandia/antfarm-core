require 'rubygems'
require 'dm-core'
require 'dm-validations'

require 'node'
require 'layer2_interface'
require 'ethernet_interface'
require 'layer3_interface'
require 'ip_interface'
require 'layer3_network'
require 'ip_network'

DataMapper.setup :default, 'sqlite3::memory:'
DataMapper.auto_migrate!
