# typed: strict
# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module Packs
    # A plugin that integrates rubocop-packs with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      #: -> LintRoller::About
      def about
        LintRoller::About.new(
          name: 'rubocop-packs',
          version: VERSION,
          homepage: 'https://github.com/rubyatscale/rubocop-packs',
          description: 'A collection of Rubocop rules for gradually modularizing a ruby codebase'
        )
      end

      #: (LintRoller::Context context) -> bool
      def supported?(context)
        context.engine == :rubocop
      end

      #: (LintRoller::Context _context) -> LintRoller::Rules
      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join('../../../config/default.yml')
        )
      end
    end
  end
end
