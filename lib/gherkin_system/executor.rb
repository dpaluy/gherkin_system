# frozen_string_literal: true

module GherkinSystem
  # Runs one compiled scenario against a test instance.
  class Executor
    # @param test [Minitest::Test]
    # @return [void]
    def self.validate!(test)
      new(test).validate!
    end

    # @param test [Minitest::Test]
    # @return [void]
    def self.call(test)
      new(test).call
    end

    # @param test [Minitest::Test]
    def initialize(test)
      @test = test
      @scenario = test.class.gherkin_scenarios.fetch(test.name.to_s)
      @run = ScenarioRun.new(@scenario)
    end

    # @return [void]
    def validate!
      @scenario.steps.each { |step| registry.resolve(step, @scenario) }
    end

    # @return [void]
    def call
      invoke_around(matching(:around)) { run_body }
    end

    private

    def registry
      GherkinSystem.step_registry
    end

    def matching(kind)
      GherkinSystem.hook_registry.matching(kind, @scenario.tags)
    end

    def invoke_around(hooks, &body)
      hook = hooks.first
      return body.call unless hook

      @run.continue_with { invoke_around(hooks.drop(1), &body) }
      @test.instance_exec(@run, &hook.block)
    end

    def run_body
      run_before
      run_steps
      @run.status = :passed
    rescue StandardError => e
      @run.status = :failed
      @run.exception = e
      raise
    ensure
      run_after
    end

    def run_before
      matching(:before).each { |hook| @test.instance_exec(@run, &hook.block) }
    end

    def run_steps
      @scenario.steps.each { |step| run_step(step) }
    end

    def run_step(step)
      definition = registry.resolve(step, @scenario)
      @test.instance_exec(*arguments(definition, step), &definition.block)
    rescue UndefinedStep, AmbiguousStep
      raise
    rescue StandardError => e
      raise StepFailure.new(@scenario, step, definition, e)
    end

    def arguments(definition, step)
      values = definition.captures(step.text, @test)
      values << step.table if step.table
      values << step.doc_string if step.doc_string
      values
    end

    def run_after
      matching(:after).reverse_each { |hook| @test.instance_exec(@run, &hook.block) }
    rescue StandardError
      raise unless @run.exception
    end
  end
end
