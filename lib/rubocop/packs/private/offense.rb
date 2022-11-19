# typed: strict

module RuboCop
  module Packs
    module Private
      class Offense < T::Struct
        extend T::Sig

        const :cop_name, String
        const :filepath, String

        sig { returns(ParsePackwerk::Package) }
        def pack
          ParsePackwerk.package_from_path(filepath)
        end
      end
    end
  end
end
