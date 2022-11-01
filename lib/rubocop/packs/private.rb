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

      sig { params(package: ParsePackwerk::Package).returns(T::Array[String]) }
      def self.validate_rubocop_todo_yml(package)
        errors = []
        rubocop_todo = package.directory.join('.rubocop_todo.yml')
        return errors unless rubocop_todo.exist?

        loaded_rubocop_todo = YAML.load_file(rubocop_todo)
        loaded_rubocop_todo.each_key do |key|
          if !Packs.config.permitted_pack_level_cops.include?(key)
            errors << <<~ERROR_MESSAGE
              #{rubocop_todo} contains invalid configuration for #{key}.
              Please ensure the only configuration is for package protection exclusions, which are one of the following cops: #{Packs.config.permitted_pack_level_cops.inspect}"
              For ignoring other cops, please instead modify the top-level .rubocop_todo.yml file.
            ERROR_MESSAGE
          elsif loaded_rubocop_todo[key].keys != ['Exclude']
            errors << <<~ERROR_MESSAGE
              #{rubocop_todo} contains invalid configuration for #{key}.
              Please ensure the only configuration for #{key} is `Exclude`
            ERROR_MESSAGE
          else
            loaded_rubocop_todo[key]['Exclude'].each do |filepath|
              return [] unless ParsePackwerk.package_from_path(filepath).name != package.name

              errors << <<~ERROR_MESSAGE
                #{rubocop_todo} contains invalid configuration for #{key}.
                #{filepath} does not belong to #{package.name}. Please ensure you only add exclusions
                for files within this pack.
              ERROR_MESSAGE
            end
          end
        end

        errors
      end
    end

    private_constant :Private
  end
end
