# typed: strict
# frozen_string_literal: true

require 'rubocop/packs/private/configuration'
require 'rubocop/packs/private/offense'

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
        client_configuration = Bundler.root.join('config/rubocop_packs.rb')
        require client_configuration.to_s if client_configuration.exist?
      end

      sig { returns(T::Array[T::Hash[T.untyped, T.untyped]]) }
      def self.rubocop_todo_ymls
        @rubocop_todo_ymls = T.let(@rubocop_todo_ymls, T.nilable(T::Array[T::Hash[T.untyped, T.untyped]]))
        @rubocop_todo_ymls ||= begin
          todo_files = Pathname.glob("**/#{PACK_LEVEL_RUBOCOP_TODO_YML}")
          todo_files.map do |todo_file|
            YAML.load_file(todo_file)
          end
        end
      end

      sig { params(package: ::Packs::Pack).returns(T::Array[String]) }
      def self.validate_rubocop_todo_yml(package)
        errors = []
        rubocop_todo = package.relative_path.join(PACK_LEVEL_RUBOCOP_TODO_YML)
        return errors unless rubocop_todo.exist?

        loaded_rubocop_todo = YAML.load_file(rubocop_todo)
        loaded_rubocop_todo.each_key do |key|
          if !Packs.config.permitted_pack_level_cops.include?(key)
            errors << <<~ERROR_MESSAGE
              #{rubocop_todo} contains invalid configuration for #{key}.
              Please only configure the following cops on a per-pack basis: #{Packs.config.permitted_pack_level_cops.inspect}"
              For ignoring other cops, please instead modify the top-level #{PACK_LEVEL_RUBOCOP_TODO_YML} file.
            ERROR_MESSAGE
          elsif loaded_rubocop_todo[key].keys != ['Exclude']
            errors << <<~ERROR_MESSAGE
              #{rubocop_todo} contains invalid configuration for #{key}.
              Please ensure the only configuration for #{key} is `Exclude`
            ERROR_MESSAGE
          else
            loaded_rubocop_todo[key]['Exclude'].each do |filepath|
              pack = ::Packs.for_file(filepath)
              next unless pack && pack.name != package.name

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

      sig { params(package: ::Packs::Pack).returns(T::Array[String]) }
      def self.validate_rubocop_yml(package)
        errors = []
        rubocop_yml = package.relative_path.join(PACK_LEVEL_RUBOCOP_YML)
        return errors unless rubocop_yml.exist?

        loaded_rubocop_yml = YAML.load_file(rubocop_yml)
        missing_keys = Packs.config.required_pack_level_cops - loaded_rubocop_yml.keys
        missing_keys.each do |key|
          errors << <<~ERROR_MESSAGE
            #{rubocop_yml} is missing configuration for #{key}.
          ERROR_MESSAGE
        end

        loaded_rubocop_yml.each_key do |key|
          if !Packs.config.permitted_pack_level_cops.include?(key)
            errors << <<~ERROR_MESSAGE
              #{rubocop_yml} contains invalid configuration for #{key}.
              Please only configure the following cops on a per-pack basis: #{Packs.config.permitted_pack_level_cops.inspect}"
              For ignoring other cops, please instead modify the top-level .rubocop.yml file.
            ERROR_MESSAGE
          elsif (loaded_rubocop_yml[key].keys - %w[Enabled FailureMode]).any?
            errors << <<~ERROR_MESSAGE
              #{rubocop_yml} contains invalid configuration for #{key}.
              Please ensure the only configuration for #{key} is `Enabled` and `FailureMode`
            ERROR_MESSAGE
          end
        end

        errors
      end

      sig { params(rule: String).returns(T::Set[String]) }
      def self.exclude_for_rule(rule)
        excludes = T.let(Set.new, T::Set[String])

        Private.rubocop_todo_ymls.each do |todo_yml|
          next if !todo_yml

          config = todo_yml[rule]
          next if config.nil?

          exclude_list = config['Exclude']
          next if exclude_list.nil?

          excludes += exclude_list
        end

        excludes
      end

      sig { params(package: ::Packs::Pack).returns(T::Array[String]) }
      def self.validate_failure_mode_strict(package)
        errors = T.let([], T::Array[String])

        Packs.config.permitted_pack_level_cops.each do |cop|
          excludes = exclude_for_rule(cop)

          rubocop_yml = package.relative_path.join(PACK_LEVEL_RUBOCOP_YML)

          next unless rubocop_yml.exist?

          loaded_rubocop_yml = YAML.load_file(rubocop_yml)
          next unless loaded_rubocop_yml[cop] && loaded_rubocop_yml[cop]['FailureMode'] == 'strict'

          excludes_for_package = excludes.select do |exclude|
            pack = ::Packs.for_file(exclude)
            pack && pack.name == package.name
          end
          next if excludes_for_package.empty?

          formatted_excludes = excludes_for_package.map { |ex| "`#{ex}`" }.join(', ')
          errors << "#{package.name} has set `#{cop}` to `FailureMode: strict` in `packs/some_pack/#{PACK_LEVEL_RUBOCOP_YML}`, forbidding new exceptions. Please either remove #{formatted_excludes} from the top-level and pack-specific `#{PACK_LEVEL_RUBOCOP_TODO_YML}` files or remove `FailureMode: strict`."
        end

        errors
      end

      sig { params(args: T.untyped).void }
      def self.execute_rubocop(args)
        RuboCop::CLI.new.run(args)
      end

      sig { params(paths: T::Array[String], cop_names: T::Array[String]).returns(T::Array[Offense]) }
      def self.offenses_for(paths:, cop_names:)
        cop_arguments = cop_names.join(',')
        # I think we can potentially use `RuboCop::CLI.new(args)` for this to avoid shelling out and starting another process that needs to reload the bundle
        args = [*paths, "--only=#{cop_arguments}", '--format=json', '--out=tmp/rubocop-output']
        FileUtils.mkdir_p('tmp')
        puts "Executing: bundle exec rubocop #{args.join(' ')}"
        Private.execute_rubocop(args)
        output = Pathname.new('tmp/rubocop-output')
        json = JSON.parse(Pathname.new('tmp/rubocop-output').read)
        output.delete
        offenses = T.let([], T::Array[Offense])
        json['files'].each do |file_hash|
          filepath = file_hash['path']
          file_hash['offenses'].each do |offense_hash|
            offenses << Offense.new(
              cop_name: offense_hash['cop_name'],
              filepath: filepath
            )
          end
        end

        offenses
      end
    end

    private_constant :Private
  end
end
