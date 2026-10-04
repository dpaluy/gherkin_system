# frozen_string_literal: true

module WelcomeSteps
  extend GherkinSystem::Steps

  When("I visit the homepage") { visit root_path }

  Then("I should see {string}") { |text| assert_text text }
end
