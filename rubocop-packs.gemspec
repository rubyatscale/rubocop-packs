Gem::Specification.new do |spec|
  spec.name          = 'rubocop-packs'
  spec.version       = '0.0.38'
  spec.authors       = ['Gusto Engineers']
  spec.email         = ['dev@gusto.com']
  spec.summary       = 'A collection of Rubocop rules for gradually modularizing a ruby codebase'
  spec.description   = 'A collection of Rubocop rules for gradually modularizing a ruby codebase'
  spec.homepage      = 'https://github.com/rubyatscale/rubocop-packs'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/rubyatscale/rubocop-packs'
    spec.metadata['changelog_uri'] = 'https://github.com/rubyatscale/rubocop-packs/releases'
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['README.md', 'lib/**/*', 'config/default.yml', 'config/pack_config.yml', 'config/erb_populated_data.yml']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency 'activesupport'
  spec.add_dependency 'packs'
  spec.add_dependency 'parse_packwerk'
  spec.add_dependency 'rubocop'
  spec.add_dependency 'rubocop-sorbet'
  spec.add_dependency 'sorbet-runtime'

  spec.add_development_dependency 'bundler', '~> 2.2.16'
  spec.add_development_dependency 'parser'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop-extension-generator'
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'tapioca'
end
