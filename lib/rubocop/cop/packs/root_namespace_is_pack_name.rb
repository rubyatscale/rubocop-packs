# typed: strict

# For String#camelize
require 'active_support/core_ext/string/inflections'
require 'rubocop/cop/packs/root_namespace_is_pack_name/desired_zeitwerk_api'

module RuboCop
  module Cop
    module Packs
      # This cop helps ensure that each pack exposes one namespace.
      # Note that this cop doesn't necessarily expect you to be using stimpack (https://github.com/rubyatscale/stimpack),
      # but it does expect packs to live in the organizational structure as described in the README.md of that gem.
      #
      # This allows packs to opt in and also prevent *other* files from sitting in their namespace.
      #
      # @example
      #
      #   # bad
      #   # packs/foo/app/services/blah/bar.rb
      #   class Blah::Bar; end
      #
      #   # good
      #   # packs/foo/app/services/foo/blah/bar.rb
      #   class Foo::Blah::Bar; end
      #
      class RootNamespaceIsPackName < Base
        extend T::Sig

        include RangeHelp

        sig { void }
        def on_new_investigation
          absolute_filepath = Pathname.new(processed_source.file_path)
          relative_filepath = absolute_filepath.relative_path_from(Pathname.pwd)
          relative_filename = relative_filepath.to_s

          # This cop only works for files ruby files in `app`
          return if !relative_filename.include?('app/') || relative_filepath.extname != '.rb'

          relative_filename = relative_filepath.to_s
          package_for_path = ParsePackwerk.package_from_path(relative_filename)
          # If a pack is using automatic pack namespaces, this protection is a no-op since zeitwerk will enforce single namespaces in that case.
          return if package_for_path.metadata['automatic_pack_namespace']

          return if package_for_path.nil?

          namespace_context = desired_zeitwerk_api.for_file(relative_filename, package_for_path)
          return if namespace_context.nil?

          allowed_global_namespaces = Set.new([
                                                namespace_context.expected_namespace,
                                                *RuboCop::Packs.config.globally_permitted_namespaces
                                              ])

          package_name = package_for_path.name
          actual_namespace = namespace_context.current_namespace
          current_fully_qualified_constant = namespace_context.current_fully_qualified_constant

          if allowed_global_namespaces.include?(actual_namespace)
            # No problem!
          else
            expected_namespace = namespace_context.expected_namespace
            relative_desired_path = namespace_context.expected_filepath
            add_offense(
              source_range(processed_source.buffer, 1, 0),
              message: format(
                'Based on the filepath, this file defines `%<current_fully_qualified_constant>s`, but it should be namespaced as `%<expected_namespace>s::%<current_fully_qualified_constant>s` with path `%<expected_path>s`.',
                package_name: package_name,
                expected_namespace: expected_namespace,
                expected_path: relative_desired_path,
                current_fully_qualified_constant: current_fully_qualified_constant
              )
            )
          end
        end

        # In the future, we'd love this to support auto-correct.
        # Perhaps by automatically renamespacing the file and changing its location?
        sig { returns(T::Boolean) }
        def support_autocorrect?
          false
        end

        private

        sig { returns(DesiredZeitwerkApi) }
        def desired_zeitwerk_api
          @desired_zeitwerk_api ||= T.let(nil, T.nilable(DesiredZeitwerkApi))
          @desired_zeitwerk_api ||= DesiredZeitwerkApi.new
        end
      end
    end
  end
end
