# frozen_string_literal: true

require "test_helper"

class ParserTest < GherkinSystemTest
  def test_outline_examples_become_separate_scenarios
    scenarios = parse(<<~FEATURE)
      Feature: Purchase

        Scenario Outline: Purchase plan
          Given I purchase "<plan>"

          Examples:
            | plan       |
            | Pro        |
            | Enterprise |
    FEATURE

    assert_equal(%w[Pro Enterprise], scenarios.map { |scenario| scenario.example_values.first })
    assert_equal "Purchase plan [Pro]", scenarios.first.test_name.split(": ", 2).last
    assert_equal ["I purchase \"Pro\""], scenarios.first.steps.map(&:text)
  end

  def test_background_is_included_once_per_scenario
    scenarios = parse(<<~FEATURE)
      Feature: Account

        Background:
          Given an account exists

        Scenario: Dashboard
          Then I see its dashboard

        Scenario: Settings
          Then I see settings
    FEATURE

    assert_equal ["an account exists", "I see its dashboard"], scenarios.first.steps.map(&:text)
    assert_equal ["an account exists", "I see settings"], scenarios.last.steps.map(&:text)
  end

  def test_data_table_and_doc_string_are_attached
    scenarios = parse(<<~FEATURE)
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
    steps = scenarios.first.steps

    assert_equal [{ "name" => "Pro", "price" => "20" }], steps.first.table.hashes
    assert_includes steps.last.doc_string, '{"plan": "pro"}'
  end

  def test_tags_are_inherited
    scenarios = parse(<<~FEATURE)
      @critical
      Feature: Checkout

        Scenario: Fast
          Given I am signed in

        @slow
        Scenario: Slow
          Given I wait
    FEATURE

    assert_equal ["@critical"], scenarios.first.tags
    assert_equal ["@critical", "@slow"], scenarios.last.tags
  end

  def test_invalid_gherkin_is_a_compilation_error
    error = assert_raises(GherkinSystem::CompilationError) { parse("This is not Gherkin") }
    assert_match(/example\.feature/, error.message)
  end

  private

  def parse(body)
    dir = write_features("example.feature" => body)
    GherkinSystem::Parser.parse_file(File.join(dir, "example.feature"))
  end
end
