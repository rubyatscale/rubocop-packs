# typed: strict
# frozen_string_literal: true

require 'rubocop/packs/private/configuration'

module RuboCop
  module Packs
    module Private
      extend T::Sig

      sig { void }
      def self.bust_cache!
        @rubocop_todo_ymls = nil
        @loaded_client_configuration = nil
      end

      sig { void }
      def self.load_client_configuration
        @loaded_client_configuration ||= T.let(false, T.nilable(T::Boolean))
        return if @loaded_client_configuration

        @loaded_client_configuration = true
        client_configuration = Pathname.pwd.join('config/rubocop_packs.rb')
        require client_configuration.to_s if client_configuration.exist?
      end

      sig { returns(T::Array[T::Hash[T.untyped, T.untyped]]) }
      def self.rubocop_todo_ymls
        @rubocop_todo_ymls = T.let(@rubocop_todo_ymls, T.nilable(T::Array[T::Hash[T.untyped, T.untyped]]))
        @rubocop_todo_ymls ||= begin
          todo_files = Pathname.glob('**/.rubocop_todo.yml')
          todo_files.map do |todo_file|
            YAML.load_file(todo_file)
          end
        end
      end
    end

    private_constant :Private
  end
end
