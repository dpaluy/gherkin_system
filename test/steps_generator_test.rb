# frozen_string_literal: true

require "test_helper"
require "open3"
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

  teardown do
    FileUtils.rm_rf(destination_root)
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

    assert_loadable_steps "test/support/gherkin/admin/billing_steps.rb", "Admin::BillingSteps"
  end

  def test_creates_deeply_nested_steps_module
    run_generator %w[admin/accounts/billing]

    assert_loadable_steps "test/support/gherkin/admin/accounts/billing_steps.rb", "Admin::Accounts::BillingSteps"
  end

  private

  def assert_loadable_steps(path, module_name)
    script = "require ARGV.fetch(0); abort unless #{module_name}.singleton_class.ancestors.include?(GherkinSystem::Steps)"
    output, error, status = Open3.capture3(
      RbConfig.ruby, "-I", File.expand_path("../lib", __dir__), "-rgherkin_system",
      "-e", script, File.join(destination_root, path)
    )

    assert status.success?, "#{output}\n#{error}"
  end
end
