# frozen_string_literal: true

require "test_helper"
require "rails"
require "rails/generators"
require "rails/generators/test_case"
require "generators/gherkin/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Gherkin::Generators::InstallGenerator
  destination File.expand_path("../tmp/generator", __dir__)

  setup do
    prepare_destination
  end

  teardown do
    FileUtils.rm_rf(destination_root)
  end

  def test_creates_loader_features_and_steps_directories
    run_generator

    assert_file "test/system/gherkin_test.rb" do |content|
      assert_match(/require "application_system_test_case"/, content)
      assert_match(%r{require "gherkin_system/rails"}, content)
      assert_match(/GherkinSystem\.configure/, content)
      assert_match(/GherkinSystem\.load!\(base: ApplicationSystemTestCase\)/, content)
    end

    assert_file "features/.keep"
    assert_file "test/support/gherkin/.keep"
  end

  def test_skips_existing_files_with_skip_flag
    run_generator
    File.write(File.join(destination_root, "test/system/gherkin_test.rb"), "# custom\n")

    run_generator ["--skip"]

    assert_file "test/system/gherkin_test.rb", "# custom\n"
  end
end
