# frozen_string_literal: true

module GherkinSystem
  # Step patterns registered by {Steps}.
  class StepRegistry
    def initialize(parameter_registry)
      @parameter_registry = parameter_registry
      @definitions = []
      @keys = {}
    end

    # @param pattern [String, Regexp]
    # @param block [Proc]
    # @return [StepDefinition]
    def register(pattern, &block)
      key = pattern.is_a?(Regexp) ? pattern.inspect : pattern.to_s
      raise DuplicateStep, "Duplicate step definition: #{key}" if @keys.key?(key)

      definition = StepDefinition.new(pattern, block, expression_for(pattern), block.source_location)
      @keys[key] = definition
      @definitions << definition
      definition
    end

    # @param step [Step]
    # @param scenario [Scenario]
    # @return [StepDefinition]
    def resolve(step, scenario)
      matches = @definitions.select { |definition| definition.matches?(step.text) }
      return matches.first if matches.one?
      raise UndefinedStep.new(scenario, step) if matches.empty?

      raise AmbiguousStep.new(scenario, step, matches)
    end

    private

    def expression_for(pattern)
      registry = @parameter_registry.registry
      if pattern.is_a?(Regexp)
        Cucumber::CucumberExpressions::RegularExpression.new(pattern, registry)
      else
        Cucumber::CucumberExpressions::CucumberExpression.new(pattern.to_s, registry)
      end
    end
  end
end
