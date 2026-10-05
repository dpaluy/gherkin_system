# frozen_string_literal: true

require "test_helper"
require "open3"

class GeneratorNamespaceTest < GherkinSystemTest
  def test_discovers_and_runs_gherkin_generators
    assert_generators_work("gherkin")
  end

  def test_discovers_and_runs_original_generator_commands
    assert_generators_work("gherkin_system")
  end

  private

  def assert_generators_work(namespace)
    destination = Dir.mktmpdir
    @dirs << destination

    invoke_generator(destination, "#{namespace}:install")
    assert_includes File.read(File.join(destination, "test/system/gherkin_test.rb")),
                    "GherkinSystem.load!(base: ApplicationSystemTestCase)"

    invoke_generator(destination, "#{namespace}:feature", "checkout")
    assert_includes File.read(File.join(destination, "features/checkout.feature")), "Feature: Checkout"

    invoke_generator(destination, "#{namespace}:steps", "checkout")
    assert_includes File.read(File.join(destination, "test/support/gherkin/checkout_steps.rb")),
                    "module CheckoutSteps"
  end

  def invoke_generator(destination, namespace, *)
    script = <<~RUBY
      require "rails"
      require "rails/generators"
      destination = ARGV.shift
      namespace = ARGV.shift
      Rails::Generators.invoke(namespace, ARGV, destination_root: destination)
    RUBY
    output, error, status = Open3.capture3(
      RbConfig.ruby, "-I", File.expand_path("../lib", __dir__), "-e", script,
      destination, namespace, *
    )

    assert status.success?, "#{namespace}: #{output}\n#{error}"
  end
end
