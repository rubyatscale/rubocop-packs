# typed: strict
# frozen_string_literal: true

module RuboCop
  module Packs
    module Private
      class Configuration
        extend T::Sig

        sig { returns(T::Array[String]) }
        attr_accessor :permitted_pack_level_cops

        sig { void }
        def initialize
          @permitted_pack_level_cops = T.let([], T::Array[String])
        end

        sig { void }
        def bust_cache!
          @permitted_pack_level_cops = []
        end
      end
    end
  end
end
