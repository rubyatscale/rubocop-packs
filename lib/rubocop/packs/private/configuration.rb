# typed: strict
# frozen_string_literal: true

module RuboCop
  module Packs
    module Private
      class Configuration
        extend T::Sig

        sig { returns(T::Array[String]) }
        attr_accessor :globally_permitted_namespaces

        sig { void }
        def initialize
          @globally_permitted_namespaces = T.let([], T::Array[String])
        end

        sig { void }
        def bust_cache!
          @globally_permitted_namespaces = []
        end
      end
    end
  end
end
