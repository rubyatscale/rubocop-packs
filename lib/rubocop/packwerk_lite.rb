# typed: strict
# frozen_string_literal: true

require 'parse_packwerk'
require 'rubocop/cop/packwerk_lite/private'
require 'rubocop/cop/packwerk_lite/constant_resolver'
require 'rubocop/cop/packwerk_lite/privacy_checker'
require 'rubocop/cop/packwerk_lite/dependency_checker'

module RuboCop
  # See docs/packwerk_lite.md
  module PackwerkLite
    class Error < StandardError; end
    extend T::Sig
  end
end
