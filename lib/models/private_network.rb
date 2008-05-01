# Private Network model for private_networks table.
#
# Copyright::       Copyright (c) 2008 Sandia National Laboratories
# Original Author:: Bryan T. Richardson <btricha@sandia.gov>
# Derived From::    code written by Michael Berg <mjberg@sandia.gov>

# PrivateNetwork class that wraps the private_networks
# table in the ANTFARM database.
#
# * has many IP networks
class PrivateNetwork < ActiveRecord::Base
  has_many :ip_networks

  # This is for ActiveScaffold
  def to_label #:nodoc:
    return "Private Network"
  end
end

