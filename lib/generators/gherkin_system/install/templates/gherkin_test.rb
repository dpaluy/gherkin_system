# frozen_string_literal: true

require "application_system_test_case"
require "gherkin_system/rails"

GherkinSystem.configure do |config|
  # config.include_steps YourSteps
end

GherkinSystem.load!(base: ApplicationSystemTestCase)
