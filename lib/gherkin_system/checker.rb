# frozen_string_literal: true

module GherkinSystem
  # Static validation. Does not execute steps or start a browser.
  class Checker
    # Collected authoring problems.
    Result = Data.define(:issues) do
      # @return [Boolean]
      def ok?
        issues.empty?
      end

      # @return [String]
      def report
        issues.map(&:message).join("\n\n")
      end
    end

    # @param glob [String, Pathname, nil]
    # @return [Result]
    def self.call(glob = nil)
      new(glob).call
    end

    # @param glob [String, Pathname, nil]
    def initialize(glob)
      @glob = glob
    end

    # @return [Result]
    def call
      Result.new(issues)
    end

    private

    def issues
      scenarios.flat_map { |scenario| step_issues(scenario) }
    rescue CompilationError => e
      [e]
    end

    def scenarios
      TagFilter.apply(FeatureLoader.load(@glob), GherkinSystem.config.tags)
    end

    def step_issues(scenario)
      scenario.steps.filter_map { |step| step_issue(scenario, step) }
    end

    def step_issue(scenario, step)
      GherkinSystem.step_registry.resolve(step, scenario)
      nil
    rescue UndefinedStep, AmbiguousStep => e
      e
    end
  end
end
