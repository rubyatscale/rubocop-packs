# typed: strict

module RuboCop
  module Cop
    module PackwerkLite
      module Private
        extend T::Sig

        sig { params(node: RuboCop::AST::ConstNode).returns(T::Boolean) }
        def self.partial_const_reference?(node)
          # This is a bit whacky, but if I have a reference in the code like this: Foo::Bar::Baz.any_method, `on_const` will be called three times:
          # One with `Foo`, one with `Foo::Bar`, and one with `Foo::Bar::Baz`.
          # As far as I can tell, there is no way to direct Rubocop to only look at the full constant name.
          # In order to ensure we're only operating on fully constant names, I check the "right sibling" of the `node`, which is the portion of the AST
          # immediately following the node.
          # If that right sibling is `nil` OR it's a lowercase string, we assume that it's the full constant.
          # If the right sibling is a non-nil capitalized string, we assume it's a part of the constant, because by convention, constants
          # start with capital letters and methods start with lowercase letters.
          # RegularRateOfPay::Types::HourlyEarningWithDate
          right_sibling = node.right_sibling
          return false if right_sibling.nil?

          right_sibling.to_s[0].capitalize == right_sibling.to_s[0]
        end

        sig { params(constant_reference: ConstantResolver::ConstantReference, type: String).returns(T::Boolean) }
        def self.violation_in_deprecated_references_yml?(constant_reference, type: 'privacy')
          existing_violations = ParsePackwerk::DeprecatedReferences.for(constant_reference.referencing_package).violations
          existing_violations.any? do |v|
            v.class_name == "::#{constant_reference.constant_name}" && (type == 'privacy' ? v.privacy? : v.dependency?)
          end
        end
      end

      private_constant :Private
    end
  end
end
