# typed: strict

module RuboCop
  module Cop
    module Packs
      class NamespaceConvention < Base
        #
        # This is a private class that represents API that we would prefer to be available somehow in Zeitwerk.
        #
        class DesiredZeitwerkApi
          extend T::Sig

          class NamespaceContext < T::Struct
            const :current_namespace, String
            const :current_fully_qualified_constant, String
            const :expected_namespace, String
            const :expected_filepath, String
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
          sig { params(relative_filename: String, package_for_path: ParsePackwerk::Package).returns(T.nilable(NamespaceContext)) }
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

            path_without_package_base = relative_filename.gsub(%r{#{package_name}/app/}, '')
            if path_without_package_base.include?('concerns')
              autoload_folder_name = path_without_package_base.split('/').first(2).join('/')
            else
              autoload_folder_name = path_without_package_base.split('/').first
            end

            remaining_file_path = path_without_package_base.gsub(%r{\A#{autoload_folder_name}/}, '')
            actual_namespace = get_actual_namespace(remaining_file_path, package_name)

            if relative_filename.include?('app/')
              app_or_lib = 'app'
            elsif relative_filename.include?('lib/')
              app_or_lib = 'lib'
            end

            absolute_desired_path = root_pathname.join(
              package_name,
              T.must(app_or_lib),
              T.must(autoload_folder_name),
              get_package_last_name(package_for_path),
              remaining_file_path
            )

            relative_desired_path = absolute_desired_path.relative_path_from(root_pathname)

            NamespaceContext.new(
              current_namespace: T.must(actual_namespace.split('::').first),
              current_fully_qualified_constant: actual_namespace,
              expected_namespace: get_pack_based_namespace(package_for_path),
              expected_filepath: relative_desired_path.to_s
            )
          end

          sig { params(pack: ParsePackwerk::Package).returns(String) }
          def get_pack_based_namespace(pack)
            get_package_last_name(pack).camelize
          end

          private

          sig { returns(Pathname) }
          def root_pathname
            Pathname.pwd
          end

          sig { params(pack: ParsePackwerk::Package).returns(String) }
          def get_package_last_name(pack)
            T.must(pack.name.split('/').last)
          end

          sig { params(remaining_file_path: String, package_name: String).returns(String) }
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
