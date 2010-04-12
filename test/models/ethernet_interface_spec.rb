require 'test/spec_helper'

# Required tests for the ANTFARM EthernetInterface model:
#
# Create
#
# Creating a model should also create a new associated layer 2 interface model
# if one is not supplied. If layer 2 interface information is supplied, the
# layer 2 interface model created should be initialized with the supplied
# information. If a layer 2 interface model is supplied, the model created
# should be associated with the supplied layer 2 interface model.
#
# Save
#
# Saving a model should not modify any information on any models associated
# with the model.
