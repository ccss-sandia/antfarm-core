require 'test/spec_helper'

# Required tests for the ANTFARM Layer3Network model:
#
# Create
#
# Creating a model should fail if no certainty factor is present (this doesn't
# mean a default value can't be set).
#
# Creating a model should fail if the certainty factor present isn't between
# the library-defined PROVEN values.
#
# Save
#
# Saving a model should fail if no certainty factor is present.
#
# Saving a model should fail if the certainty factor present isn't between
# the library-defined PROVEN values.
#
# Destroy
#
# Destoying a model should also destroy any and all layer 3 interface and IP
# network models associated with the model.
#
# Search
#
# If an IP network associated with a layer 3 network contains an IP address
# supplied, the layer 3 network should be returned. Otherwise, a new IP network
# should be created (which will automatically cause a new layer 3 network to be
# created) and the associated layer 3 network should be returned.
