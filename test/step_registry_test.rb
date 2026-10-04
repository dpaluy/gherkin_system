# frozen_string_literal: true

require "test_helper"

class StepRegistryTest < GherkinSystemTest
  def test_expression_captures_string_and_int
    definition = registry.register("I have {int} {string} products") { |count, name| [count, name] }
    test = Object.new

    assert_equal [2, "Pro"], definition.captures('I have 2 "Pro" products', test)
  end

  def test_regex_captures_strings
    definition = registry.register(/^I have (\d+) products$/) { |count| count }
    test = Object.new

    assert_equal [3], definition.captures("I have 3 products", test)
  end

  def test_custom_parameter_type_transforms_on_the_test_instance
    GherkinSystem.parameter_registry.define(
      name: "user",
      regexp: /alice|bob/,
      type: String,
      transformer: ->(name) { "#{name}:#{receiver}" }
    )
    definition = registry.register("I am {user}") { |user| user }
    test = Object.new
    def test.receiver = "test"

    assert_equal ["alice:test"], definition.captures("I am alice", test)
  end

  def test_duplicate_pattern_is_rejected
    registry.register("I am signed in") { nil }

    error = assert_raises(GherkinSystem::DuplicateStep) do
      registry.register("I am signed in") { nil }
    end
    assert_includes error.message, "I am signed in"
  end

  def test_ambiguous_step_lists_definitions
    registry.register("I am signed in") { nil }
    registry.register(/^I am signed in$/) { nil }
    scenario = scenario_for("I am signed in")
    step = scenario.steps.first

    error = assert_raises(GherkinSystem::AmbiguousStep) { registry.resolve(step, scenario) }
    assert_includes error.message, "Matching definitions:"
  end

  def test_undefined_step_suggests_a_snippet
    scenario = scenario_for('I purchase the "Enterprise" plan', keyword: "When")
    step = scenario.steps.first

    error = assert_raises(GherkinSystem::UndefinedStep) { registry.resolve(step, scenario) }
    assert_includes error.message, 'When("I purchase the {string} plan") do |string|'
    assert_includes error.message, "pending"
    assert_includes error.message, "features/system/subscriptions.feature:18"
  end

  private

  def registry
    GherkinSystem.step_registry
  end

  def scenario_for(text, keyword: "Given")
    step = GherkinSystem::Step.new(text: text, keyword: keyword, line: 18, table: nil, doc_string: nil)
    GherkinSystem::Scenario.new(
      uri: "features/system/subscriptions.feature",
      feature_name: "Subscriptions",
      name: "Purchase",
      tags: [],
      example_values: [],
      line: 10,
      scenario_line: 10,
      steps: [step]
    )
  end
end
