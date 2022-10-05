# frozen_string_literal: true

require 'rubocop'

require_relative 'rubocop/modularization'
require_relative 'rubocop/modularization/inject'

RuboCop::Modularization::Inject.defaults!

require_relative 'rubocop/cop/modularization_cops'
