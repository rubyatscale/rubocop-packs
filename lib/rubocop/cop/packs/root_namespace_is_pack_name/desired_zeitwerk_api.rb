# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Packs
      class RootNamespaceIsPackName < Base
        #
        # This is a private class that represents API that we would prefer to be available somehow in Zeitwerk.
        # However, the boundaries between systems (packwerk/zeitwerk, rubocop/zeitwerk) are poor in this class, so
        # that would need to be separated prior to proposing any API changes in zeitwerk.
        #
        class DesiredZeitwerkApi
          class NamespaceContext
            #: String
            attr_reader :current_namespace

            #: String
            attr_reader :current_fully_qualified_constant

            #: String
            attr_reader :expected_namespace

            #: String
            attr_reader :expected_filepath

            #: (current_namespace: String, current_fully_qualified_constant: String, expected_namespace: String, expected_filepath: String) -> void
            def initialize(current_namespace:, current_fully_qualified_constant:, expected_namespace:, expected_filepath:)
              @current_namespace = current_namespace
              @current_fully_qualified_constant = current_fully_qualified_constant
              @expected_namespace = expected_namespace
              @expected_filepath = expected_filepath
            end
          end

          #
          # For now, this API includes `package_for_path`
          # If this were truly zeitwerk API, it wouldn't include any mention of packs and it would likely not need the package at all
          # Since it could get the actual namespace without knowing anything about packs.
          # However, we would need to pass to it the desired namespace based on the pack name for it to be able to suggest
          # a desired filepath.
          # Likely this means that our own cop should determine the desired namespace and pass that in
          # and this can determine actual namespace and how to get to expected.
          #
          #: (String relative_filename, ::Packs::Pack package_for_path) -> NamespaceContext?
          def for_file(relative_filename, package_for_path)
            package_name = package_for_path.name

            # Zeitwerk establishes a standard convention by which namespaces are defined.
            # The package protections namespace checker is coupled to a specific assumption about how auto-loading works.
            #
            # Namely, we expect the following autoload paths: `packs/**/app/**/`
            # Examples:
            # 1) `packs/package_1/app/public/package_1/my_constant.rb` produces constant `Package1::MyConstant`
            # 2) `packs/package_1/app/services/package_1/my_service.rb` produces constant `Package1::MyService`
            # 3) `packs/package_1/app/services/package_1.rb` produces constant `Package1`
            # 4) `packs/package_1/app/public/package_1.rb` produces constant `Package1`
            #
            # Described another way, we expect any part of the directory labeled NAMESPACE to establish a portion of the fully qualified runtime constant:
            # `packs/**/app/**/NAMESPACE1/NAMESPACE2/[etc]`
            #
            # Therefore, for our implementation, we substitute out the non-namespace producing portions of the filename to count the number of namespaces.
            # Note this will *not work* properly in applications that have different assumptions about autoloading.

            path_without_package_base = relative_filename.gsub(%r(#{package_name}/app/), '')
            if path_without_package_base.include?('/concerns/')
              autoload_folder_name = path_without_package_base.split('/').first(2).join('/')
            else
              autoload_folder_name = path_without_package_base.split('/').fetch(0)
            end

            remaining_file_path = path_without_package_base.gsub(%r(\A#{autoload_folder_name}/), '')
            actual_namespace = get_actual_namespace(remaining_file_path, package_name)

            app_or_lib =
              if relative_filename.include?('app/')
                'app'
              elsif relative_filename.include?('lib/')
                'lib'
              else
                raise ArgumentError, "#{relative_filename} is in neither app/ nor lib/"
              end

            absolute_desired_path = root_pathname.join(
              package_name,
              app_or_lib,
              autoload_folder_name,
              package_for_path.last_name,
              remaining_file_path
            )

            relative_desired_path = absolute_desired_path.relative_path_from(root_pathname)

            NamespaceContext.new(
              current_namespace: actual_namespace.split('::').fetch(0),
              current_fully_qualified_constant: actual_namespace,
              expected_namespace: get_pack_based_namespace(package_for_path),
              expected_filepath: relative_desired_path.to_s
            )
          end

          #: (::Packs::Pack pack) -> String
          def get_pack_based_namespace(pack)
            pack.last_name.camelize
          end

          private

          #: -> Pathname
          def root_pathname
            Pathname.pwd
          end

          #: (String remaining_file_path, String package_name) -> String
          def get_actual_namespace(remaining_file_path, package_name)
            # If the remaining file path is a ruby file (not a directory), then it establishes a global namespace
            # Otherwise, per Zeitwerk's conventions as listed above, its a directory that establishes another global namespace
            remaining_file_path.split('/').map { |entry| entry.gsub('.rb', '').camelize }.join('::')
          end
        end

        private_constant :DesiredZeitwerkApi
      end
    end
  end
end
