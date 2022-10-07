# typed: strict
# frozen_string_literal: true

require 'rubocop'
require 'parse_packwerk'

require_relative 'rubocop/modularization'
require_relative 'rubocop/modularization/inject'

require 'rubocop/cop/modularization/namespaced_under_package_name'
require 'rubocop/cop/modularization/typed_public_api'
require 'rubocop/cop/modularization/class_methods_as_public_apis'
require 'rubocop/cop/modularization/require_documented_public_apis'

RuboCop::Modularization::Inject.defaults!
