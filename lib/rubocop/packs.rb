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

    # We can remove this function once package_protections is fully deprecated
    sig { params(rule: String).returns(T::Set[String]) }
    def self.exclude_for_rule(rule)
      Private.exclude_for_rule(rule)
    end

    #
    # Note: when we add per-pack `.rubocop.yml` files, we'll want to add some validations here
    # to restrict what cops are permitted to be configured in those files.
    # We might also want further (configurable?) constraints *requiring* that the "permitted pack level cops" be specified explicitly.
    #
    sig { returns(T::Array[String]) }
    def self.validate
      errors = T.let([], T::Array[String])
      ParsePackwerk.all.each do |package|
        next if package.name == ParsePackwerk::ROOT_PACKAGE_NAME
        errors += Private.validate_rubocop_todo_yml(package)
        errors += Private.validate_rubocop_yml(package)
        errors += Private.validate_failure_mode_strict(package)
      end

      errors
    end
  end
end
