# typed: strict
# frozen_string_literal: true

module RuboCop
  module Packs
    module Private
      class Configuration
        #: Array[String]
        attr_accessor :globally_permitted_namespaces

        #: -> void
        def initialize
          @globally_permitted_namespaces = [] #: Array[String]
        end

        #: -> void
        def bust_cache!
          @globally_permitted_namespaces = []
        end
      end
    end
  end
end
