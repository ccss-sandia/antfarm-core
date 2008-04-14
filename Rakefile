require 'rake/gempackagetask'

spec = Gem::Specification.new do |s| 
  s.name = "ANTFARM"
  s.version = "0.1.0"
  s.author = "Michael Berg & Bryan Richardson"
  s.email = "mjberg@sandia.gov & btricha@sandia.gov"
# s.homepage = "http://antfarm.rubyforge.org"
  s.platform = Gem::Platform::RUBY
  s.summary = "Passive network mapping tool"
  s.files = FileList["{bin,config,db,lib,log,rails}/**/*"].to_a
# s.require_path = "lib"
# s.autorequire = "name"
  s.executables << 'antfarm'
# s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = false
# s.extra_rdoc_files = ["README"]
  s.add_dependency("rails", ">= 2.0.2")
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end 
