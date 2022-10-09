# typed: strict

require 'rubocop-sorbet'

module RuboCop
  module Cop
    module Packs
      # This cop helps ensure that each pack's public API is strictly typed, enforcing strong boundaries.
      #
      # @example
      #
      #   # bad
      #   # packs/foo/app/public/foo.rb
      #   # typed: false
      #   module Foo; end
      #
      #   # good
      #   # packs/foo/app/public/foo.rb
      #   # typed: strict
      #   module Foo; end
      #
      class TypedPublicApi < Sorbet::StrictSigil
        #
        # This inherits from `Sorbet::StrictSigil` and doesn't change any behavior of it.
        # The only reason we do this is so that configuration for this cop can live under a different cop namespace.
        # This prevents this cop's configuration from clashing with other configurations for the same cop.
        # A concrete example of this would be if a user is using this package protection to make sure public APIs are typed,
        # and separately the application as a whole requiring strict typing in certain parts of the application.
        #
        # To prevent problems associated with needing to manage identical configurations for the same cop, we simply call it
        # something else in the context of this protection.
        #
        # We can apply this same pattern if we want to use other cops in the context of package protections and prevent clashing.
        #
        extend T::Sig

        sig { params(processed_source: T.untyped).void }
        def investigate(processed_source)
          return unless processed_source.path.include?('app/public')
          super
        end
      end
    end
  end
end
