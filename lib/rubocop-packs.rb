# typed: strict
# frozen_string_literal: true

require 'rubocop'
require 'parse_packwerk'

require_relative 'rubocop/packs'
require_relative 'rubocop/packs/inject'
require_relative 'rubocop/packwerk_lite'

require 'rubocop/cop/packs/namespace_convention'
require 'rubocop/cop/packs/typed_public_api'
require 'rubocop/cop/packs/class_methods_as_public_apis'
require 'rubocop/cop/packs/require_documented_public_apis'
require 'rubocop/cop/packs/zeitwerk_friendly_constant'

RuboCop::Packs::Inject.defaults!
