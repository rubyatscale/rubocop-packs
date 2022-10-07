# typed: strict
# frozen_string_literal: true

require 'rubocop'
require 'parse_packwerk'

require_relative 'rubocop/packs'
require_relative 'rubocop/packs/inject'

require 'rubocop/cop/packs/namespaced_under_package_name'
require 'rubocop/cop/packs/typed_public_api'
require 'rubocop/cop/packs/class_methods_as_public_apis'
require 'rubocop/cop/packs/require_documented_public_apis'

RuboCop::Packs::Inject.defaults!
