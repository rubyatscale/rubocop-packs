# typed: strict
# frozen_string_literal: true

require 'rubocop/packs/private/configuration'

module RuboCop
  module Packs
    module Private
      #: -> void
      def self.bust_cache!
        @loaded_client_configuration = nil
      end

      #: -> void
      def self.load_client_configuration
        @loaded_client_configuration ||= false #: bool?
        return if @loaded_client_configuration

        @loaded_client_configuration = true
        client_configuration = Bundler.root.join('config/rubocop_packs.rb')
        require client_configuration.to_s if client_configuration.exist?
      end
    end

    private_constant :Private
  end
end
