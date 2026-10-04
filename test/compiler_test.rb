# frozen_string_literal: true

require "test_helper"

class CompilerTest < GherkinSystemTest
  class Host < Minitest::Test
  end

  def test_each_pickle_is_a_minitest_method_on_the_given_base
    dir = write_features("purchase.feature" => <<~FEATURE)
      Feature: Purchase

        Scenario Outline: Purchase plan
          Given I purchase "<plan>"

          Examples:
            | plan       |
            | Pro        |
            | Enterprise |
    FEATURE

    klasses = load_features(dir, base: Host)
    klass = klasses.first

    assert_equal Host, klass.superclass
    assert_match(/\AGherkinSystem::Suite::Purchase/, klass.name)
    assert_equal 2, scenario_methods(klass).size
    assert(scenario_methods(klass).any? { |name| name.include?("Pro") })
    assert(scenario_methods(klass).any? { |name| name.include?("Enterprise") })
  end

  def test_tag_expression_drops_scenarios
    dir = write_features("checkout.feature" => <<~FEATURE)
      Feature: Checkout

        @critical
        Scenario: Fast
          Given I am signed in

        @slow
        Scenario: Slow
          Given I wait
    FEATURE
    GherkinSystem.configure { |config| config.tags = "@critical and not @slow" }

    klass = load_features(dir, base: Host).first

    assert_equal 1, scenario_methods(klass).size
    assert_includes scenario_methods(klass).first, "Fast"
  end

  def test_line_filter_keeps_the_scenario_on_that_line
    body = <<~FEATURE
      Feature: Checkout

        Scenario: Fast
          Given I am signed in

        Scenario: Slow
          Given I wait
    FEATURE
    dir = write_features("checkout.feature" => body)
    path = File.join(dir, "checkout.feature")
    slow_line = File.readlines(path).index { |line| line.include?("Scenario: Slow") } + 1
    ENV["GHERKIN_FEATURES"] = path
    ENV["GHERKIN_LINE"] = slow_line.to_s

    klass = load_features(dir, base: Host).first

    assert_equal 1, scenario_methods(klass).size
    assert_includes scenario_methods(klass).first, "Slow"
  end

  def test_unset_tag_filter_compiles_every_scenario
    dir = write_features("checkout.feature" => <<~FEATURE)
      Feature: Checkout

        @critical
        Scenario: Fast
          Given I am signed in

        @slow
        Scenario: Slow
          Given I wait
    FEATURE

    klass = load_features(dir, base: Host).first

    assert_equal 2, scenario_methods(klass).size
  end

  def test_missing_base_class_raises
    error = assert_raises(GherkinSystem::ConfigurationError) { GherkinSystem.load!("*.feature") }
    assert_includes error.message, "base:"
  end
end
