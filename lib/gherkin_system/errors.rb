# frozen_string_literal: true

require "minitest"

module GherkinSystem
  # Base error for gherkin_system failures.
  class Error < StandardError; end

  # Raised when load configuration is missing or inconsistent.
  class ConfigurationError < Error; end

  # Raised when a feature, tag expression, or hook cannot be compiled.
  class CompilationError < Error; end

  # Raised when the same step pattern is registered twice.
  class DuplicateStep < Error; end

  # Formats a bin/rails gherkin rerun hint for a scenario location.
  module Rerun
    module_function

    # @param scenario [Scenario]
    # @param line [Integer, nil]
    # @return [Array<String>]
    def footer(scenario, line = scenario.line)
      ["", "Rerun:", "  bin/rails gherkin #{location(scenario, line)}"]
    end

    # @param scenario [Scenario]
    # @param line [Integer, nil]
    # @return [String]
    def location(scenario, line = scenario.line)
      "#{display_path(scenario.uri)}:#{line}"
    end

    # @param uri [String]
    # @return [String]
    def display_path(uri)
      path = uri.to_s
      root = project_root
      return path if root.nil? || root.empty?

      absolute = File.expand_path(path)
      prefix = "#{File.expand_path(root)}/"
      return absolute.delete_prefix(prefix) if absolute.start_with?(prefix)

      path
    end

    # @return [String, nil]
    def project_root
      return Rails.root.to_s if defined?(Rails) && Rails.respond_to?(:root) && Rails.root

      Dir.pwd
    end
  end

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
        "#{Rerun.display_path(scenario.uri)}:#{step.line}",
        "",
        "Suggested definition:",
        "",
        Snippet.for(step),
        *Rerun.footer(scenario)
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
        "#{Rerun.display_path(scenario.uri)}:#{step.line}",
        "",
        "Matching definitions:",
        *locations,
        *Rerun.footer(scenario)
      ].join("\n")
    end
  end

  # Wraps a step exception with the feature and definition locations.
  # Subclasses Minitest::Assertion so wrapped failures report as Failures.
  class StepFailure < Minitest::Assertion
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
        "#{Rerun.display_path(scenario.uri)}:#{step.line}",
        "",
        cause.message.to_s,
        "",
        "Step definition:",
        definition.location_label,
        *Rerun.footer(scenario)
      ].join("\n")
    end
  end
end
