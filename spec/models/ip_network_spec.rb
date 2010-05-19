require 'spec/spec_helper'

# Required tests for the ANTFARM IpNetwork model:
#
# Create
#
# Creating a model should also create a new associated layer 3 network model
# if one is not supplied. If layer 3 network information is supplied, the
# layer 3 network model created should be initialized with the supplied
# information. If a layer 3 network model is supplied, the model created
# should be associated with the supplied layer 3 network model.
#
# Save
#
# Saving a model should not modify any information on any models associated
# with the model.
