# frozen_string_literal: true

require "cucumber/tag_expressions"

module GherkinSystem
  # Selects scenarios with a Cucumber tag expression.
  module TagFilter
    module_function

    # @param scenarios [Array<Scenario>]
    # @param expression [String, nil]
    # @return [Array<Scenario>]
    def apply(scenarios, expression)
      return scenarios if expression.nil? || expression.strip.empty?

      parsed = Cucumber::TagExpressions::Parser.new.parse(expression)
      scenarios.select { |scenario| parsed.evaluate(scenario.tags) }
    rescue CompilationError
      raise
    rescue StandardError => e
      raise CompilationError, "Invalid tag expression #{expression.inspect}: #{e.message}"
    end
  end
end
