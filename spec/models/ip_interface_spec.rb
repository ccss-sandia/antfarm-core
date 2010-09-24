################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

require 'spec/spec_helper'

# Required tests for the ANTFARM IpInterface model:
#
# Create
#
# Creating an IP interface model is a special case that differs from creating an
# ethernet interface or IP network model. This is due to the fact that the IP
# interface's associated layer 3 interface model belongs to both a layer 3
# network and a layer 2 interface model. Rather than allowing the layer 3
# interface to create its own layer 3 network directly, the IP interface model
# should first search for or create an IP network model it belongs to (which
# will create an associated layer 3 network model directly), then supply the
# newly created layer 3 network to the layer 3 interface when it's created.
# While the search or creation of an IP network should ALWAYS happen when an IP
# interface is created, the creation of an ethernet interface should ONLY
# happen if ethernet interface information is supplied to the IP interface when
# it's being created. A similar process should follow for layer 2 interface
# associations to the layer 3 interface, whereby an ethernet interface is first
# created, then the layer 2 interface it created is automatically passed to the
# layer 3 interface when it's being created.
#
# If the given IP address for the model being created is contained within an
# existing IP network, that IP network's associated layer 3 network should be
# used with the layer 3 interface being created. Otherwise, a new IP network
# should be created (restating what's somewhat hidden in the above paragraph).
#
# Save
#
# Saving a model should not modify any information on any models associated
# with the model.

describe Antfarm::Model::IpInterface, '#create' do
  it 'should fail if no address exists' do
    iface = Antfarm::Model::IpInterface.create
    iface.valid?.should == false
    iface.saved?.should == false
  end

  it 'should fail if the address is not in IP address format' do
    iface = Antfarm::Model::IpInterface.create :address => 'foo.bar'
    iface.valid?.should == false
    iface.saved?.should == false
  end

  it 'should not create any new associated models if invalid' do
    l3_iface_count = Antfarm::Model::LayerThreeInterface.all.length
    l3_net_count   = Antfarm::Model::LayerThreeNetwork.all.length
    ip_net_count   = Antfarm::Model::IpNetwork.all.length

    iface = Antfarm::Model::IpInterface.create

    iface.valid?.should == false
    Antfarm::Model::LayerThreeInterface.all.length.should == l3_iface_count
    Antfarm::Model::LayerThreeNetwork.all.length.should == l3_net_count
    Antfarm::Model::IpNetwork.all.length.should == ip_net_count
  end

  it 'should create new associated models if valid' do
    l3_iface_count = Antfarm::Model::LayerThreeInterface.all.length
    l3_net_count   = Antfarm::Model::LayerThreeNetwork.all.length
    ip_net_count   = Antfarm::Model::IpNetwork.all.length

    iface = Antfarm::Model::IpInterface.create :address => '192.168.101.1/24'

    iface.valid?.should == true
    Antfarm::Model::LayerThreeInterface.all.length.should == l3_iface_count + 1
    Antfarm::Model::LayerThreeNetwork.all.length.should == l3_net_count + 1
    Antfarm::Model::IpNetwork.all.length.should == ip_net_count + 1
    iface.layer_three_interface.should == Antfarm::Model::LayerThreeInterface.all.last
  end
end
