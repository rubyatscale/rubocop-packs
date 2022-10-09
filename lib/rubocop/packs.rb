# typed: strict
# frozen_string_literal: true

require 'rubocop/packs/private'

module RuboCop
  module Packs
    class Error < StandardError; end
    extend T::Sig

    # Your code goes here...
    PROJECT_ROOT   = T.let(Pathname.new(__dir__).parent.parent.expand_path.freeze, Pathname)
    CONFIG_DEFAULT = T.let(PROJECT_ROOT.join('config', 'default.yml').freeze, Pathname)
    CONFIG         = T.let(YAML.safe_load(CONFIG_DEFAULT.read).freeze, T.untyped)

    private_constant(:CONFIG_DEFAULT, :PROJECT_ROOT)

    #
    # Ideally, this is API that is available to us via `rubocop` itself.
    # That is: the ability to preserve the location of `.rubocop_todo.yml` files and associate
    # exclusions with the closest ancestor `.rubocop_todo.yml`
    #
    sig { params(packs: T::Array[ParsePackwerk::Package]).void }
    def self.auto_generate_rubocop_todo(packs:)
      pack_arguments = packs.map(&:name).join(' ')
      cop_arguments = config.permitted_pack_level_cops.join(',')
      command = "bundle exec rubocop #{pack_arguments} --only=#{cop_arguments} --format=json"
      puts "Executing: #{command}"
      json = JSON.parse(`#{command}`)
      new_rubocop_todo_exclusions = {}
      json['files'].each do |file_hash|
        filepath = file_hash['path']
        pack = ParsePackwerk.package_from_path(filepath)
        next if pack.name == ParsePackwerk::ROOT_PACKAGE_NAME

        file_hash['offenses'].each do |offense_hash|
          cop_name = offense_hash['cop_name']
          next unless config.permitted_pack_level_cops.include?(cop_name)

          new_rubocop_todo_exclusions[pack.name] ||= {}
          new_rubocop_todo_exclusions[pack.name][filepath] ||= []
          new_rubocop_todo_exclusions[pack.name][filepath] << cop_name
        end
      end

      new_rubocop_todo_exclusions.each do |pack_name, file_hash|
        pack = T.must(ParsePackwerk.find(pack_name))
        rubocop_todo_yml = pack.directory.join('.rubocop_todo.yml')
        if rubocop_todo_yml.exist?
          rubocop_todo = YAML.load_file(rubocop_todo_yml)
        else
          rubocop_todo = {}
        end
        file_hash.each do |file, failing_cops|
          failing_cops.each do |failing_cop|
            rubocop_todo[failing_cop] ||= { 'Exclude' => [] }
            rubocop_todo[failing_cop]['Exclude'] << file
          end
        end

        next if rubocop_todo.empty?

        rubocop_todo_yml.write(YAML.dump(rubocop_todo))
      end
    end

    sig { params(root_pathname: String).returns(String) }
    # It would be great if rubocop (upstream) could take in a glob for `inherit_from`, which
    # would allow us to delete this method and this additional complexity.
    def self.pack_based_rubocop_todos(root_pathname: Bundler.root)
      rubocop_todos = {}
      # We do this because when the ERB is evaluated Dir.pwd is at the directory containing the YML.
      # Ideally rubocop wouldn't change the PWD before invoking this method.
      Dir.chdir(root_pathname) do
        ParsePackwerk.all.each do |package|
          next if package.name == ParsePackwerk::ROOT_PACKAGE_NAME

          rubocop_todo = package.directory.join('.rubocop_todo.yml')
          next unless rubocop_todo.exist?

          loaded_rubocop_todo = YAML.load_file(rubocop_todo)
          loaded_rubocop_todo.each do |protection_key, key_config|
            rubocop_todos[protection_key] ||= { 'Exclude' => [] }
            rubocop_todos[protection_key]['Exclude'] += key_config['Exclude']
          end
        end
      end

      YAML.dump(rubocop_todos)
    end

    sig { void }
    def self.bust_cache!
      config.bust_cache!
      Private.bust_cache!
    end

    sig { params(blk: T.proc.params(arg0: Private::Configuration).void).void }
    def self.configure(&blk)
      yield(config)
    end

    sig { returns(Private::Configuration) }
    def self.config
      Private.load_client_configuration
      @config = T.let(@config, T.nilable(Private::Configuration))
      @config ||= Private::Configuration.new
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

    sig { returns(T::Array[String]) }
    def self.validate
      errors = []
      ParsePackwerk.all.each do |package|
        next if package.name == ParsePackwerk::ROOT_PACKAGE_NAME

        rubocop_todo = package.directory.join('.rubocop_todo.yml')
        next unless rubocop_todo.exist?

        loaded_rubocop_todo = YAML.load_file(rubocop_todo)
        loaded_rubocop_todo.each_key do |key|
          if !config.permitted_pack_level_cops.include?(key)
            errors << <<~ERROR_MESSAGE
              #{rubocop_todo} contains invalid configuration for #{key}.
              Please ensure the only configuration is for package protection exclusions, which are one of the following cops: #{config.permitted_pack_level_cops.inspect}"
              For ignoring other cops, please instead modify the top-level .rubocop_todo.yml file.
            ERROR_MESSAGE
          elsif loaded_rubocop_todo[key].keys != ['Exclude']
            errors << <<~ERROR_MESSAGE
              #{rubocop_todo} contains invalid configuration for #{key}.
              Please ensure the only configuration for #{key} is `Exclude`
            ERROR_MESSAGE
          else
            loaded_rubocop_todo[key]['Exclude'].each do |filepath|
              next unless ParsePackwerk.package_from_path(filepath).name != package.name

              errors << <<~ERROR_MESSAGE
                #{rubocop_todo} contains invalid configuration for #{key}.
                #{filepath} does not belong to #{package.name}. Please ensure you only add exclusions
                for files within this pack.
              ERROR_MESSAGE
            end
          end
        end
      end

      errors
    end
  end
end
