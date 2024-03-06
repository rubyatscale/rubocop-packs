# typed: strict
# frozen_string_literal: true

require 'rubocop/packs/private/configuration'
require 'rubocop/packs/private/offense'

module RuboCop
  module Packs
    module Private
      extend T::Sig

      sig { returns(Integer) }
      def self.bust_cache!
        @loaded_client_configuration = nil
      end

      sig { void }
      def self.load_client_configuration
        @loaded_client_configuration ||= T.let(false, T.nilable(T::Boolean))
        return if @loaded_client_configuration

        @loaded_client_configuration = true
        client_configuration = Bundler.root.join('config/rubocop_packs.rb')
        require client_configuration.to_s if client_configuration.exist?
      end
    end

    private_constant :Private
  end
end
