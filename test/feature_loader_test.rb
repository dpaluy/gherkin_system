# frozen_string_literal: true

require "test_helper"

class FeatureLoaderTest < GherkinSystemTest
  def test_default_glob_loads_root_and_existing_system_features
    dir = Dir.mktmpdir
    @dirs << dir
    FileUtils.mkdir_p(File.join(dir, "features", "system"))
    File.write(File.join(dir, "features", "checkout.feature"), <<~FEATURE)
      Feature: Checkout

        Scenario: Buy
          When I buy
    FEATURE
    File.write(File.join(dir, "features", "system", "welcome.feature"), <<~FEATURE)
      Feature: Welcome

        Scenario: Hello
          When I visit
    FEATURE

    Dir.chdir(dir) do
      scenarios = GherkinSystem::FeatureLoader.load

      assert_equal %w[Checkout Welcome], scenarios.map(&:feature_name).sort
    end
  end

  def test_directory_filter_selects_features_under_the_path
    dir = write_nested_features
    ENV["GHERKIN_FEATURES"] = dir

    scenarios = GherkinSystem::FeatureLoader.load(File.join(dir, "**/*.feature"))

    assert_equal 2, scenarios.size
    assert_equal %w[Checkout Welcome], scenarios.map(&:feature_name).sort
  end

  def test_subdirectory_filter_narrows_features
    dir = write_nested_features
    ENV["GHERKIN_FEATURES"] = File.join(dir, "system")

    scenarios = GherkinSystem::FeatureLoader.load(File.join(dir, "**/*.feature"))

    assert_equal 1, scenarios.size
    assert_equal "Welcome", scenarios.first.feature_name
  end

  def test_unmatched_path_filter_raises
    dir = write_nested_features
    ENV["GHERKIN_FEATURES"] = File.join(dir, "missing")

    error = assert_raises(GherkinSystem::ConfigurationError) do
      GherkinSystem::FeatureLoader.load(File.join(dir, "**/*.feature"))
    end

    assert_includes error.message, "No scenarios matched"
    assert_includes error.message, "missing"
  end

  def test_unmatched_line_filter_raises
    dir = write_nested_features
    path = File.join(dir, "system", "welcome.feature")
    ENV["GHERKIN_FEATURES"] = path
    ENV["GHERKIN_LINE"] = "999"

    error = assert_raises(GherkinSystem::ConfigurationError) do
      GherkinSystem::FeatureLoader.load(File.join(dir, "**/*.feature"))
    end

    assert_includes error.message, "No scenarios matched"
    assert_includes error.message, ":999"
  end

  def test_no_filter_allows_empty_glob
    dir = Dir.mktmpdir
    @dirs << dir

    assert_empty GherkinSystem::FeatureLoader.load(File.join(dir, "**/*.feature"))
  end

  private

  def write_nested_features
    dir = Dir.mktmpdir
    @dirs << dir
    FileUtils.mkdir_p(File.join(dir, "system"))
    FileUtils.mkdir_p(File.join(dir, "other"))
    File.write(File.join(dir, "system", "welcome.feature"), <<~FEATURE)
      Feature: Welcome

        Scenario: Hello
          When I visit
    FEATURE
    File.write(File.join(dir, "other", "checkout.feature"), <<~FEATURE)
      Feature: Checkout

        Scenario: Buy
          When I buy
    FEATURE
    dir
  end
end
