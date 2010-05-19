require 'test/spec_helper'

# Required tests for the ANTFARM Layer3Interface model:
#
# Create
#
# Creating a model should fail if no certainty factor is present (this doesn't
# mean a default value can't be set).
#
# Creating a model should fail if the certainty factor present isn't between
# the library-defined PROVEN values.
#
# Creating a model should also create a new associated layer 2 interface model
# if one is not supplied. If layer 2 interface information is supplied, the
# layer 2 interface model created should be initialized with the supplied
# information. If a layer 2 interface model is supplied, the model created
# should be associated with the supplied layer 2 interface model.
#
# Creating a model should also create a new associated layer 3 network model
# if one is not supplied. If layer 3 network information is supplied, the
# layer 3 network model created should be initialized with the supplied
# information. If a layer 3 network model is supplied, the model created
# should be associated with the supplied layer 3 network model.
#
# Note that in all cases, the layer 3 network model should be supplied to the
# layer 3 interface when it's being created (see notes on IpInterface to
# understand why).
#
# Save
#
# Saving a model should fail if no certainty factor is present.
#
# Saving a model should fail if the certainty factor present isn't between
# the library-defined PROVEN values.
#
# Saving a model should not modify any information on any models associated
# with the model.
#
# Destroy
#
# Destoying a model should also destroy any and all IP interface models
# associated with the model.
