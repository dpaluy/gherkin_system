# frozen_string_literal: true

module GherkinSystem
  # Base error for gherkin_system failures.
  class Error < StandardError; end

  # Raised when load configuration is missing or inconsistent.
  class ConfigurationError < Error; end

  # Raised when a feature, tag expression, or hook cannot be compiled.
  class CompilationError < Error; end

  # Raised when the same step pattern is registered twice.
  class DuplicateStep < Error; end

  # Raised when no step definition matches.
  class UndefinedStep < Error
    # @param scenario [Scenario]
    # @param step [Step]
    def initialize(scenario, step)
      super(self.class.format(scenario, step))
    end

    def self.format(scenario, step)
      [
        "Undefined step:",
        "",
        "  #{step.keyword} #{step.text}",
        "",
        "#{scenario.uri}:#{step.line}",
        "",
        "Suggested definition:",
        "",
        Snippet.for(step)
      ].join("\n")
    end
  end

  # Raised when more than one step definition matches.
  class AmbiguousStep < Error
    # @param scenario [Scenario]
    # @param step [Step]
    # @param definitions [Array<StepDefinition>]
    def initialize(scenario, step, definitions)
      super(self.class.format(scenario, step, definitions))
    end

    def self.format(scenario, step, definitions)
      locations = definitions.map { |definition| "  #{definition.location_label}" }
      [
        "Ambiguous step:",
        "",
        "  #{step.keyword} #{step.text}",
        "",
        "#{scenario.uri}:#{step.line}",
        "",
        "Matching definitions:",
        *locations
      ].join("\n")
    end
  end

  # Wraps a step exception with the feature and definition locations.
  class StepFailure < Error
    # @return [Exception] the original failure
    attr_reader :cause

    # @param scenario [Scenario]
    # @param step [Step]
    # @param definition [StepDefinition]
    # @param cause [Exception]
    def initialize(scenario, step, definition, cause)
      super(self.class.format(scenario, step, definition, cause))
      @cause = cause
      set_backtrace(cause.backtrace)
    end

    def self.format(scenario, step, definition, cause)
      [
        scenario.feature_name,
        "  #{scenario.name}",
        "",
        "FAILED",
        "",
        "#{step.keyword} #{step.text}",
        "#{scenario.uri}:#{step.line}",
        "",
        cause.message.to_s,
        "",
        "Step definition:",
        definition.location_label
      ].join("\n")
    end
  end
end
