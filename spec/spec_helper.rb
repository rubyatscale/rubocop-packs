# typed: strict
# frozen_string_literal: true

require 'bundler/setup'
require 'rubocop-packs'
require 'rubocop/rspec/support'
require 'packs/rspec/support'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include RuboCop::RSpec::ExpectOffense

  config.around do |example|
    ParsePackwerk.bust_cache!
    RuboCop::Packs.bust_cache!
    example.run
  end

  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.order = :random
  Kernel.srand config.seed
end
