# frozen_string_literal: true

require "test_helper"
require "rails"
require "rails/generators"
require "rails/generators/test_case"
require "generators/gherkin_system/steps/steps_generator"

class StepsGeneratorTest < Rails::Generators::TestCase
  tests GherkinSystem::Generators::StepsGenerator
  destination File.expand_path("../tmp/generator", __dir__)
  arguments %w[checkout]

  setup do
    prepare_destination
  end

  def test_creates_steps_module
    run_generator

    assert_file "test/support/gherkin/checkout_steps.rb" do |content|
      assert_match(/module CheckoutSteps/, content)
      assert_match(/extend GherkinSystem::Steps/, content)
    end
  end

  def test_creates_nested_steps_module
    run_generator %w[admin/billing]

    assert_file "test/support/gherkin/admin/billing_steps.rb" do |content|
      assert_match(/module Admin::BillingSteps/, content)
    end
  end
end
