# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Original Author: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or (at
# your option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 

require 'rake/gempackagetask'
require 'rake/rdoctask'

spec = Gem::Specification.new do |s| 
  s.name = "antfarm"
  s.version = "0.3.0"
  s.author = "Michael Berg and Bryan Richardson"
  s.email = "btricha@sandia.gov and mjberg@sandia.gov"
  s.homepage = "http://antfarm.rubyforge.org"
  s.rubyforge_project = "antfarm"
  s.platform = Gem::Platform::RUBY
  s.summary = "Passive network mapping tool"
  s.files = FileList["{bin,config,db,lib,log,rails,templates,tmp}/**/*", "CHANGELOG", "LICENSE"].exclude("lib/misc", "lib/graph", "lib/scripts/viz/render-graph.rb").to_a
  s.executables << 'antfarm'
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
  s.add_dependency("activerecord", ">= 2.0.2")
  s.add_dependency("sqlite3-ruby", ">= 1.2.2")
  s.requirements << 'libsqlite3-dev'
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
  pkg.need_zip = true 
end 

namespace :doc do
  Rake::RDocTask.new("antfarm") do |rdoc|
    rdoc.rdoc_dir = 'doc/antfarm'
    rdoc.title = 'ANTFARM Application Documentation, Version 0.3.0'
    rdoc.rdoc_files.include('README')
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.rdoc_files.exclude('lib/graph', 'lib/misc', 'lib/scripts')
  end
end
