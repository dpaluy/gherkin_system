# frozen_string_literal: true

require "test_helper"
require "rails"
require "rails/generators"
require "rails/generators/test_case"
require "generators/gherkin_system/feature/feature_generator"

class FeatureGeneratorTest < Rails::Generators::TestCase
  tests GherkinSystem::Generators::FeatureGenerator
  destination File.expand_path("../tmp/generator", __dir__)
  arguments %w[checkout]

  setup do
    prepare_destination
  end

  def test_creates_feature_file
    run_generator

    assert_file "features/system/checkout.feature" do |content|
      assert_match(/Feature: Checkout/, content)
      assert_match(/Scenario: Replace with the condition and result/, content)
    end
  end

  def test_creates_nested_feature_file
    run_generator %w[admin/billing]

    assert_file "features/system/admin/billing.feature" do |content|
      assert_match(/Feature: Billing/, content)
    end
  end
end
