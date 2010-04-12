require 'test/spec_helper'

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
# created, then the layer 2 interface it created automatically is passed to the
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
