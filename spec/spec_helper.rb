# typed: strict
# frozen_string_literal: true

require 'bundler/setup'
require 'rubocop-packs'
require 'rubocop/rspec/support'
require_relative 'support/application_fixture_helper'
require 'pry'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include RuboCop::RSpec::ExpectOffense
  config.include ApplicationFixtureHelper
  config.around do |example|
    ::Packs.bust_cache!
    ParsePackwerk.bust_cache!
    RuboCop::Packs.bust_cache!
    example.run
  end

  config.around do |example|
    prefix = [File.basename($0), Process.pid].join('-') # rubocop:disable Style/SpecialGlobalVars
    tmpdir = Dir.mktmpdir(prefix)
    Dir.chdir(tmpdir) do
      example.run
    end
  ensure
    FileUtils.rm_rf(T.must(tmpdir))
  end

  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.order = :random
  Kernel.srand config.seed
end
