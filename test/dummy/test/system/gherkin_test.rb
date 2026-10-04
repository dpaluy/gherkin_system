# frozen_string_literal: true

require "application_system_test_case"
require_relative "../support/gherkin/welcome_steps"

GherkinSystem.configure do |config|
  config.include_steps WelcomeSteps
end

GherkinSystem.load!(base: ApplicationSystemTestCase)
