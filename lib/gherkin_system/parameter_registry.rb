# frozen_string_literal: true

require "cucumber/cucumber_expressions/parameter_type"
require "cucumber/cucumber_expressions/parameter_type_registry"

module GherkinSystem
  # Custom Cucumber Expressions parameter types.
  class ParameterRegistry
    # @return [Cucumber::CucumberExpressions::ParameterTypeRegistry]
    attr_reader :registry

    def initialize
      @registry = Cucumber::CucumberExpressions::ParameterTypeRegistry.new
    end

    # @param name [String]
    # @param regexp [Regexp, String]
    # @param transformer [Proc]
    # @param type [Class]
    # @param prefer_for_regexp_match [Boolean]
    # @return [void]
    def define(name:, regexp:, transformer:, type: String, prefer_for_regexp_match: false)
      parameter = Cucumber::CucumberExpressions::ParameterType.new(
        name,
        regexp,
        type || String,
        transformer,
        true,
        prefer_for_regexp_match
      )
      registry.define_parameter_type(parameter)
    end
  end
end
