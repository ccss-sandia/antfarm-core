Gem::Specification.new do |s| 
  s.name              = %q{antfarm-core}
  s.version           = '0.5.0'
  s.authors           = ['Bryan T. Richardson']
  s.email             = %q{scada@sandia.gov}
  s.date              = %q{2010-06-01}
  s.summary           = %q{Antfarm core}
  s.description       = %q{Antfarm core project}
  s.homepage          = %q{http://ccss-sandia.github.com/antfarm-core}
  s.files             = Dir['{config,lib}/**/*','README.md'].to_a
  s.require_paths     = ['lib']
  s.has_rdoc          = false

  s.add_dependency 'dm-core'
  s.add_dependency 'data_objects'
  s.add_dependency 'do_sqlite3'
  s.add_dependency 'dm-constraints'
  s.add_dependency 'dm-validations'
  s.add_dependency 'antfarm-plugins'
end
