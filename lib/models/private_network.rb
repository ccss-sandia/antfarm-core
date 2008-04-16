# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>

class PrivateNetwork < ActiveRecord::Base
  has_many :ip_networks

  # This is for ActiveScaffold
  def to_label
    return "Private Network"
  end
end

