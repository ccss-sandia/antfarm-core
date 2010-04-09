require 'spec/rake/spectask'

SPEC_SUITES = [
  { :id => :models, :title => 'models', :files => %w(test/models/*_spec.rb) }
]

namespace :spec do
  SPEC_SUITES.each do |suite|
    desc "Run all specs in #{suite[:title]} spec suite"
    Spec::Rake::SpecTask.new(suite[:id]) do |t|
      files = []

      if suite[:files]
        suite[:files].each { |glob| files += Dir[glob] }
      end

      if suite[:dirs]
        suite[:dirs].each { |glob| files += Dir["#{glob}/**/*_spec.rb"] }
      end

      t.spec_files = files
    end
  end
end
