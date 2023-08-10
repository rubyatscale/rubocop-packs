# typed: strict
# frozen_string_literal: true

require 'rubocop'
require 'packs-specification'

require_relative 'rubocop/packs'
require_relative 'rubocop/packs/inject'
require_relative 'rubocop/packwerk_lite'

require 'rubocop/cop/packs/root_namespace_is_pack_name'
require 'rubocop/cop/packs/typed_public_apis'
require 'rubocop/cop/packs/class_methods_as_public_apis'
require 'rubocop/cop/packs/documented_public_apis'

RuboCop::Packs::Inject.defaults!
