# frozen_string_literal: true

require "test_helper"

class CheckerTest < GherkinSystemTest
  def test_check_reports_undefined_steps_without_executing_them
    dir = write_features("missing.feature" => <<~FEATURE)
      Feature: Missing

        Scenario: No definition
          When I purchase the "Enterprise" plan
    FEATURE

    result = GherkinSystem::Checker.call(File.join(dir, "*.feature"))

    refute result.ok?
    assert_includes result.report, "Undefined step:"
    assert_includes result.report, "{string}"
  end

  def test_check_passes_when_every_step_is_defined
    dir = write_features("ready.feature" => <<~FEATURE)
      Feature: Ready

        Scenario: Signed in
          Given I am signed in
    FEATURE
    Module.new do
      extend GherkinSystem::Steps

      Given("I am signed in") { nil }
    end

    result = GherkinSystem::Checker.call(File.join(dir, "*.feature"))

    assert result.ok?
  end

  def test_check_reports_invalid_gherkin
    dir = write_features("broken.feature" => "This is not Gherkin")

    result = GherkinSystem::Checker.call(File.join(dir, "*.feature"))

    refute result.ok?
    assert_includes result.report, "broken.feature"
  end

  def test_check_reports_invalid_tag_expressions
    dir = write_features("tagged.feature" => <<~FEATURE)
      Feature: Tagged

        Scenario: One
          Given I am signed in
    FEATURE
    GherkinSystem.configure { |config| config.tags = "@critical and" }

    result = GherkinSystem::Checker.call(File.join(dir, "*.feature"))

    refute result.ok?
    assert_includes result.report, "Invalid tag expression"
  end

  def test_malformed_hook_tags_fail_at_registration
    error = assert_raises(GherkinSystem::CompilationError) do
      Module.new do
        extend GherkinSystem::Hooks

        Before("(((") { nil }
      end
    end

    assert_includes error.message, "Malformed hook tag expression"
  end
end
