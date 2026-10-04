# frozen_string_literal: true

require "test_helper"
require "stringio"

class ExecutorTest < GherkinSystemTest
  class OrderCase < Minitest::Test
    attr_reader :events

    def before_setup
      @events = []
      @events << :rails_setup
      super
    end
  end

  class FlagCase < Minitest::Test
    attr_reader :super_called

    def before_setup
      @super_called = true
      super
    end
  end

  def test_steps_run_with_instance_exec_and_share_ivars
    dir = write_features("account.feature" => <<~FEATURE)
      Feature: Account

        Scenario: Dashboard
          Given an account exists
          Then I see its dashboard
    FEATURE
    register_account_steps
    klass = load_features(dir, base: OrderCase).first
    test = run_scenario(klass)

    assert_empty test.failures
    assert_equal "acme", test.instance_variable_get(:@seen)
  end

  def test_hooks_wrap_steps_and_after_runs_when_a_step_raises
    dir = write_features("hooks.feature" => <<~FEATURE)
      @external
      Feature: Hooks

        Scenario: Wrapped
          Given a step
    FEATURE
    register_hook_steps
    klass = load_features(dir, base: OrderCase).first
    test = run_scenario(klass)

    assert_equal %i[rails_setup around_before before step after passed around_after], test.events
    assert_empty test.failures
  end

  def test_after_hook_runs_when_the_step_fails
    dir = write_features("hooks.feature" => <<~FEATURE)
      Feature: Hooks

        Scenario: Broken
          Given a failing step
    FEATURE
    register_hook_steps
    klass = load_features(dir, base: OrderCase).first
    test = run_scenario(klass)

    assert_includes test.events, :after
    assert_includes test.events, :failed
    refute_empty test.failures
  end

  def test_table_hashes_and_doc_strings_are_passed_through
    dir = write_features("catalog.feature" => <<~FEATURE)
      Feature: Catalog

        Scenario: Products
          Given these products exist:
            | name | price |
            | Pro  | 20    |
          When I submit this JSON:
            """
            {"plan": "pro"}
            """
    FEATURE
    register_catalog_steps
    klass = load_features(dir, base: OrderCase).first
    test = run_scenario(klass)

    assert_empty test.failures, test.failures.map(&:message).join("\n")
    assert_equal [{ "name" => "Pro", "price" => "20" }], test.instance_variable_get(:@hashes)
    assert_includes test.instance_variable_get(:@json), '{"plan": "pro"}'
  end

  def test_undefined_step_fails_before_super
    dir = write_features("missing.feature" => <<~FEATURE)
      Feature: Missing

        Scenario: No definition
          When I purchase the "Enterprise" plan
    FEATURE
    klass = load_features(dir, base: FlagCase).first
    test = run_scenario(klass)

    refute test.super_called
    assert_includes test.failures.first.message, "Undefined step:"
  end

  def test_strict_false_reaches_super_before_the_missing_step_fails
    dir = write_features("missing.feature" => <<~FEATURE)
      Feature: Missing

        Scenario: No definition
          When I purchase the "Enterprise" plan
    FEATURE
    GherkinSystem.configure { |config| config.strict = false }
    klass = load_features(dir, base: FlagCase).first
    test = run_scenario(klass)

    assert test.super_called
    assert_includes test.failures.first.message, "Undefined step:"
  end

  def test_included_step_module_methods_are_available
    dir = write_features("helpers.feature" => <<~FEATURE)
      Feature: Helpers

        Scenario: Helper
          Given use helper
    FEATURE
    GherkinSystem.configure { |config| config.include_steps(register_helper_steps) }
    klass = load_features(dir, base: OrderCase).first
    test = run_scenario(klass)

    assert_empty test.failures
    assert_equal "helper", test.instance_variable_get(:@value)
  end

  def test_failure_names_the_feature_step_and_definition
    dir = write_features("checkout.feature" => <<~FEATURE)
      Feature: Checkout

        Scenario: Customer purchases Pro
          Then the order should be paid
    FEATURE
    register_checkout_steps
    klass = load_features(dir, base: OrderCase).first
    failure = run_scenario(klass).failures.first
    message = failure.message

    assert_kind_of Minitest::Assertion, failure
    assert_kind_of GherkinSystem::StepFailure, failure
    assert_includes message, "Checkout"
    assert_includes message, "Customer purchases Pro"
    assert_includes message, "the order should be paid"
    assert_includes message, "checkout.feature:"
    assert_includes message, "Expected Order#paid? to be truthy."
    assert_includes message, "Step definition:"
    assert_match(/executor_test\.rb:\d+/, message)
    assert_includes message, "bin/rails gherkin"
    assert_includes message, "checkout.feature:3"
  end

  def test_assertion_failures_include_gherkin_context
    dir = write_features("checkout.feature" => <<~FEATURE)
      Feature: Checkout

        Scenario: Customer purchases Pro
          Then the order should be paid
    FEATURE
    Module.new do
      extend GherkinSystem::Steps

      Then("the order should be paid") { flunk "Expected Order#paid? to be truthy." }
    end
    klass = load_features(dir, base: OrderCase).first
    failure = run_scenario(klass).failures.first
    message = failure.message

    assert_kind_of GherkinSystem::StepFailure, failure
    assert_kind_of Minitest::Assertion, failure.cause
    assert_includes message, "Checkout"
    assert_includes message, "the order should be paid"
    assert_includes message, "checkout.feature:"
    assert_includes message, "Expected Order#paid? to be truthy."
    assert_includes message, "bin/rails gherkin"
  end

  def test_after_hook_sees_failed_status_for_assertion
    dir = write_features("hooks.feature" => <<~FEATURE)
      Feature: Hooks

        Scenario: Broken assert
          Given a flunking step
    FEATURE
    Module.new do
      extend GherkinSystem::Steps
      extend GherkinSystem::Hooks

      After { |scenario| @events = [scenario.status] }
      Given("a flunking step") { flunk "nope" }
    end
    klass = load_features(dir, base: OrderCase).first
    test = run_scenario(klass)

    assert_equal [:failed], test.instance_variable_get(:@events)
    assert_kind_of GherkinSystem::StepFailure, test.failures.first
  end

  def test_skipped_step_remains_a_skip_in_the_reporter
    result = reported_step { skip "not available" }
    output = StringIO.new
    reporter = Minitest::SummaryReporter.new(output)
    reporter.start
    reporter.record(result)
    reporter.report

    assert_instance_of Minitest::Skip, result.failure
    assert_equal "not available", result.failure.message
    assert_equal "S", result.result_code
    assert reporter.passed?
    assert_includes output.string, "0 failures, 0 errors, 1 skips"
  end

  def test_reporter_counts_wrapped_and_native_failures
    output = StringIO.new
    reporter = Minitest::SummaryReporter.new(output)
    reporter.start
    reporter.record(reported_step { flunk "assertion failed" })
    reporter.record(reported_step { raise "runtime failed" })
    native_case = Class.new(Minitest::Test) do
      def test_assertion = flunk "native assertion"
      def test_error = raise "native error"
      def test_skip = skip "native skip"
    end
    %w[test_assertion test_error test_skip].each do |name|
      reporter.record(native_case.new(name).run)
    end
    reporter.report

    refute reporter.passed?
    assert_includes output.string, "3 failures, 1 errors, 1 skips"
    assert_includes output.string, "assertion failed"
    assert_includes output.string, "runtime failed"
    assert_includes output.string, "Step definition:"
  end

  private

  def reported_step(&block)
    GherkinSystem.reset_configuration!
    dir = write_features("report.feature" => <<~FEATURE)
      Feature: Reporting

        Scenario: Step result
          Given a reported step
    FEATURE
    Module.new do
      extend GherkinSystem::Steps

      Given("a reported step", &block)
    end
    klass = load_features(dir, base: OrderCase).first
    klass.new(scenario_methods(klass).first).run
  end

  def register_account_steps
    Module.new do
      extend GherkinSystem::Steps

      Given("an account exists") { @account = "acme" }
      Then("I see its dashboard") { @seen = @account }
    end
  end

  def register_hook_steps
    Module.new do
      extend GherkinSystem::Steps
      extend GherkinSystem::Hooks

      Before { @events << :before }
      After do |scenario|
        @events << :after
        @events << scenario.status
      end
      Around("@external") do |scenario|
        @events << :around_before
        scenario.run
        @events << :around_after
      end
      Given("a step") { @events << :step }
      Given("a failing step") do
        @events << :step
        raise "boom"
      end
    end
  end

  def register_catalog_steps
    Module.new do
      extend GherkinSystem::Steps

      Given("these products exist:") { |table| @hashes = table.hashes }
      When("I submit this JSON:") { |json| @json = json }
    end
  end

  def register_helper_steps
    Module.new do
      extend GherkinSystem::Steps

      def helper_value = "helper"

      Given("use helper") { @value = helper_value }
    end
  end

  def register_checkout_steps
    Module.new do
      extend GherkinSystem::Steps

      Then("the order should be paid") { raise "Expected Order#paid? to be truthy." }
    end
  end
end
