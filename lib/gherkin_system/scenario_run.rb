# frozen_string_literal: true

module GherkinSystem
  # Object yielded to hooks. Around hooks continue the scenario with {#run}.
  class ScenarioRun
    # @return [String]
    attr_reader :name

    # @return [String]
    attr_reader :feature_name

    # @return [Array<String>]
    attr_reader :tags

    # @return [Exception, nil]
    attr_accessor :exception

    # @return [Symbol]
    attr_accessor :status

    # @param scenario [Scenario]
    def initialize(scenario)
      @name = scenario.name
      @feature_name = scenario.feature_name
      @tags = scenario.tags
      @status = :pending
      @exception = nil
    end

    # Continues the hook chain or the scenario body.
    #
    # @return [void]
    def run
      @continuation.call
    end

    # @return [void]
    def continue_with(&block)
      @continuation = block
    end
  end
end
