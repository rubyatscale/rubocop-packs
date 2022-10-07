# typed: strict
# frozen_string_literal: true

require 'rubocop/modularization/private'

module RuboCop
  module Modularization
    class Error < StandardError; end
    extend T::Sig

    # Your code goes here...
    PROJECT_ROOT   = T.let(Pathname.new(__dir__).parent.parent.expand_path.freeze, Pathname)
    CONFIG_DEFAULT = T.let(PROJECT_ROOT.join('config', 'default.yml').freeze, Pathname)
    CONFIG         = T.let(YAML.safe_load(CONFIG_DEFAULT.read).freeze, T.untyped)

    private_constant(:CONFIG_DEFAULT, :PROJECT_ROOT)
  end
end
