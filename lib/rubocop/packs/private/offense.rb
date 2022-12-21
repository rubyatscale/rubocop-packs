# typed: strict

module RuboCop
  module Packs
    module Private
      class Offense < T::Struct
        extend T::Sig

        const :cop_name, String
        const :filepath, String

        sig { returns(T.nilable(::Packs::Pack)) }
        def pack
          ::Packs.for_file(filepath)
        end
      end
    end
  end
end
