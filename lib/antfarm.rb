# Copyright 2004 Sandia National Laboratories
# Original Author: Michael Berg <mjberg@sandia.gov>

module Antfarm

  # Symbolic marker points on the fuzzy logic certainty factor scale.
  # Certainty Factors (CF)
  CF_PROVEN_TRUE    =  1.0000
  CF_LIKELY_TRUE    =  0.5000
  CF_LACK_OF_PROOF  =  0.0000
  CF_LIKELY_FALSE   = -0.5000
  CF_PROVEN_FALSE   = -1.0000

  # Amount by which a value can differ and still be considered the same.
  # Mainly used as a buffer against floating point round-off errors.
  CF_VARIANCE       =  0.0001

  def self.clamp(x, low = CF_PROVEN_FALSE, high = CF_PROVEN_TRUE)
    if x < low
      return low
    elsif x > high
      return high
    else
      return x
    end
  end

  def self.simplify_interfaces
    #TODO
  end

  def self.timestamp
    return Time.now.utc.xmlschema
  end
end
