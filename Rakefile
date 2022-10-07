# typed: ignore

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# There appears to be a bug when publishing where requires don't work as expected in the context of a publish: https://github.com/rubyatscale/rubocop-modularization/actions/runs/3204938570/jobs/5236826621
# For now, this should be fixed by not loading these tasks except when needed. I'd like to fix this but this is lower priority at the moment!
if ENV['VERIFYING_DOCUMENTATION']
  Dir['tasks/**/*.rake'].each { |t| load t }
end

task(default: %i[documentation_syntax_check generate_cops_documentation spec])

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc 'Generate a new cop with a template'
task :new_cop, [:cop] do |_task, args|
  require 'rubocop'

  cop_name = args.fetch(:cop) do
    warn 'usage: bundle exec rake new_cop[Department/Name]'
    exit!
  end

  generator = RuboCop::Cop::Generator.new(cop_name)

  generator.write_source
  generator.write_spec
  generator.inject_require(root_file_path: 'lib/rubocop/cop/modularization_cops.rb')
  generator.inject_config(config_file_path: 'config/default.yml')

  puts generator.todo
end
