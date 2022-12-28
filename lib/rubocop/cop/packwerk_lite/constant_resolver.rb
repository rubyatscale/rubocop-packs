# typed: strict

module RuboCop
  module Cop
    module PackwerkLite
      #
      # This is a private class that represents API that we would prefer to be available somehow in Zeitwerk.
      # However, the boundaries between systems (packwerk/zeitwerk, rubocop/zeitwerk) are poor in this class, so
      # that would need to be separated prior to proposing any API changes in zeitwerk.
      #
      class ConstantResolver
        extend T::Sig

        class ConstantReference < T::Struct
          extend T::Sig

          const :constant_name, String
          const :global_namespace, String
          const :source_package, ParsePackwerk::Package
          const :constant_definition_location, Pathname
          const :referencing_file, Pathname

          sig { returns(ParsePackwerk::Package) }
          def referencing_package
            ParsePackwerk.package_from_path(referencing_file)
          end

          sig { returns(T::Boolean) }
          def public_api?
            # PackwerkExtensions should have a method to take in a path and determine if the file is public.
            # For now we put it here and only support the public folder (and not specific private constants).
            # However if we declare that dependency we may want to extract this into `rubocop-packwerk_lite` or something liek that!
            constant_definition_location.to_s.include?('/public/')
          end

          sig { params(node: RuboCop::AST::ConstNode, processed_source: RuboCop::AST::ProcessedSource).returns(T.nilable(ConstantReference)) }
          def self.resolve(node, processed_source)
            constant_name = node.const_name
            namespaces = constant_name.split('::')
            global_namespace = namespaces.first

            expected_containing_pack_last_name = global_namespace.underscore

            # We don't use Packs.find(...) here because we want to look for nested packs, and this pack could be a child pack in a nested pack too.
            # In the future, we might want `find` to be able to take a glob or a regex to look for packs with a specific name structure.
            expected_containing_pack = ParsePackwerk.all.find { |p| p.name.include?("/#{expected_containing_pack_last_name}") }
            return if expected_containing_pack.nil?

            if namespaces.count == 1
              found_files = expected_containing_pack.directory.glob("app/*/#{expected_containing_pack_last_name}.rb")
            else
              expected_location_in_pack = namespaces[1..].map(&:underscore).join('/')
              found_files = expected_containing_pack.directory.glob("app/*/#{expected_containing_pack_last_name}/#{expected_location_in_pack}.rb")
            end

            # Because of how Zietwerk works, we know two things:
            # 1) Since namespaces map one to one with files, Zeitwerk does not permit multiple files to define the same fully-qualified class/module.
            # (Note it does permit multiple files to open up portions of other namespaces)
            # 2) If a file *could* define a fully qualified constant, then it *must* define that constant!
            #
            # Therefore when we've found possible files, we can sanity check there is only one,
            # and then assume the found pack defines the constant!
            raise if found_files.count > 1

            expected_pack_contains_constant = found_files.any?

            return if !expected_pack_contains_constant

            found_file = found_files.first

            ConstantReference.new(
              constant_name: constant_name,
              global_namespace: global_namespace,
              source_package: expected_containing_pack,
              constant_definition_location: T.must(found_file),
              referencing_file: Pathname.new(processed_source.path).relative_path_from(Pathname.pwd)
            )
          end
        end
      end

      private_constant :ConstantResolver
    end
  end
end
