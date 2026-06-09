# typed: false
# frozen_string_literal: true

SimpleCov.start do
  enable_coverage :branch

  # Track only the cops (and their direct helpers); the gate enforces that the
  # cop surface is fully exercised.
  add_filter { |src| !src.filename.include?('/lib/rubocop/cop/') }

  # Enforce full coverage on complete runs (and when COVERAGE=true), but not
  # when running a single spec file locally.
  if ENV['COVERAGE'] == 'true' || ARGV.none? { |arg| arg.end_with?('_spec.rb') }
    minimum_coverage line: 100, branch: 100
  end
end
