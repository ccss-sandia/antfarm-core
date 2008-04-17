require 'rake/gempackagetask'

spec = Gem::Specification.new do |s| 
  s.name = "ANTFARM"
  s.version = "0.2.0"
  s.author = "Michael Berg & Bryan Richardson"
  s.email = "mjberg@sandia.gov & btricha@sandia.gov"
# s.homepage = "http://antfarm.rubyforge.org"
  s.platform = Gem::Platform::RUBY
  s.summary = "Passive network mapping tool"
  s.files = FileList["{bin,config,db,lib,log,rails}/**/*"].exclude("lib/misc").to_a
  s.executables << 'antfarm'
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
  s.add_dependency("rails", ">= 2.0.2")
  s.add_dependency("sqlite3-ruby", ">= 1.2.1")
  s.requirements << 'libsqlite3-dev'
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end 
