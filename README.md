# ANTFARM-CORE

ANTFARM (Advanced Network Toolkit For Assessments and Remote Mapping) is a
passive network mapping application that utilizes output from existing network
examination tools to populate its OSI-modeled database. This data can then be
used to form a ‘picture’ of the network being analyzed.

ANTFARM can also be described as a data fusion tool that does not directly
interact with the network. The analyst can use a variety of passive or active
data gathering techniques, the outputs of which are loaded into ANTFARM and
incorporated into the network map. Data gathering can be limited to completely
passive techniques when minimizing the risk of disrupting the operational
network is a concern.

This library implements the core ANTFARM functionality, which mainly facilitates
creating and interacting with the relational database that holds and correlates
network data as it is parsed. This library is not meant to stand alone, but
rather be part of a larger application needing ANTFARM functionality. Please
see the ANTFARM (as opposed to the ANTFARM-CORE) library if you are looking for
the command-line application.

## HOW IT WORKS

At the center of the ANTFARM-CORE library is a boot-strapping and initialization
process very similar to the one used in Rails applications. The boot-strapping
and initialization process sets the root directory, the environment to use (used
by the database and logging features), the log level to use, and loads in all
the database models (see below).

DataMapper is used as the ORM for interacting with the database, and models
exist for the following database tables:

* Node
* LayerTwoInterface
* EthernetInterface
* LayerThreeInterface
* IpInterface
* LayerThreeNetwork
* IpNetwork

These models live in the Antfarm::Model namespace.

A framework is provided to facilitate interaction with plugins and manipulation
of the database.

## THINGS TO KNOW

The ANTFARM environment and log settings can (and should) be set via the
described environment variables below as long as they are set before the
config/environment.rb file is loaded.

    ENV['ANTFARM_ENV'] = 'foo'
    ENV['ANTFARM_LOG_LEVEL'] = 'debug'

When ANTFARM is boot-strapped, it will check to see if a .antfarm directory
exists in the home directory of the current user and will create it if not.
This is where application-specific data is stored, like default environment
and log level settings, database settings, SQLite3 databases (if used), and
log files. Custom user plugins can also be placed in the .antfarm directory
and they will be recognized by the plugins library.

## DATABASE SETTINGS

Right now, only SQLite3 is supported. As such, it is the default. Future plans
include supporting Postgres as well, in which case different databases can be
configured for different environments via the default settings in the .antfarm
directory.

## PLUGINS

Detailed information for each plugin is provided via the ANTFARM-PLUGINS man
page (`gem man antfarm-plugins`). Plugins included in the core library are
located in the 'lib/antfarm/plugins/' directory, and custom plugins created by
a user would/should be located in the '~/.antfarm/plugins' directory.

## HOW TO WRITE A PLUGIN

The requirements for a plugin are as follows:

* Plugin must belong to the Antfarm::Plugin namespace
* Below the Antfarm::Plugin namespace, namespacing must follow the directory
  structure of the location of the plugin
* Plugin must include the Antfarm::Plugin module
* Plugin must provide a hash that describes the plugin and an array of hashes
  that describe possible plugin options to 'super' in the constructor
** Required description options are :name, :desc, and :author
** Required parameter options are :name, :desc, :type, :default and :required
* Plugin must implement a 'run' method that accepts a single hash parameter
** The single hash parameter will contain options provided as described in the
   constructor

Here is a very simple example plugin located at 'plugins/custom/foo-bar.rb':

    module Antfarm
      module Plugin
        module Custom
          class FooBar
            include Antfarm::Plugin

            def initialize
              super( { :name => 'Foo Bar Plugin',
                       :desc => 'This plugin does nothing',
                       :author => 'Me <me@you.com>' },
                    [{ :name => :input_file,
                       :desc => 'File that has data in it',
                       :type => String,
                       :required => true },
                     { :name => :use,
                       :desc => 'To use or not to use' }
                   ])
            end

            def run(options)
              # options[:input_file] will contain a string
              # options[:use] will either be true or false, depending on whether or
              # not the user provided the flag
              
              # TODO: do something!
              # Database models can be used like so:
              #   Antfarm::Model::IpInterface.create :address => 'w.x.y.z'
            end
          end
        end
      end
    end

Note that for optional parameters, if a type is not provided it is assumed to be
a flag (true if the flag is provided, false if not). Obviously the default will
be false and it is not required.

## VERSIONING INFORMATION

This project uses the major/minor/bugfix method of versioning. It has yet to
reach a 1.x.x status yet because the API is still in flux.

## DISCLAIMER

While the ANTFARM-CORE library is completely passive (it does not have any
built-in means of gathering data directly from devices or networks), network
admin tools that users of ANTFARM may choose to gather data with may or may not
be passive. The authors of ANTFARM hold no responsibility in how users decide to
gather data they wish to feed into ANTFARM.

## COPYRIGHT

Copyright (2008-2010) Sandia Corporation. Under the terms of Contract
DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains certain
rights in this software.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place, Suite 330, Boston, MA 02111-1307 USA.
