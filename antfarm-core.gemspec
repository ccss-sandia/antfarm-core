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

Gem::Specification.new do |s| 
  s.name          = %q{antfarm-core}
  s.version       = '0.5.0.beta1'
  s.authors       = ['Bryan T. Richardson']
  s.email         = %q{scada@sandia.gov}
  s.date          = %q{2010-09-27}
  s.summary       = %q{Framework providing API for ANTFARM}
  s.description   = %q{ANTFARM is a passive network mapping tool capable of
                       parsing data files generated by common network
                       administration tools, network equipment configuration
                       files, etc. Designed for use when assessing critical
                       infrastructure control systems.

                       This library provides an API application developers
                       can use when embedding ANTFARM functionality into an
                       existing application or when creating a new user
                       interface for ANTFARM.}
  s.homepage      = %q{http://ccss-sandia.github.com/antfarm-core}
  s.files         = Dir['{config,lib,man}/**/*','README.md'].to_a
  s.require_paths = ['lib']
  s.has_rdoc      = false

  s.add_dependency 'dm-core',        '0.10.2'
  s.add_dependency 'data_objects',   '0.10.2'
  s.add_dependency 'do_sqlite3',     '0.10.2'
  s.add_dependency 'dm-constraints', '0.10.2'
  s.add_dependency 'dm-validations', '0.10.2'
end
