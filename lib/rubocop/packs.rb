# typed: strict
# frozen_string_literal: true

require 'rubocop/packs/private'

module RuboCop
  module Packs
    #: -> void
    def self.bust_cache!
      config.bust_cache!
      Private.bust_cache!
    end

    #: { (Private::Configuration arg0) -> void } -> void
    def self.configure(&blk)
      yield(config)
    end

    #: -> Private::Configuration
    def self.config
      Private.load_client_configuration
      @config ||= Private::Configuration.new #: Private::Configuration?
    end
  end
end
