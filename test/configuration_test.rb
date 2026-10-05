# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < GherkinSystemTest
  def test_tags_follow_the_environment_until_set
    ENV["GHERKIN_TAGS"] = "@critical"

    assert_equal "@critical", GherkinSystem.config.tags

    GherkinSystem.configure { |config| config.tags = nil }

    assert_nil GherkinSystem.config.tags
  end

  def test_default_features_use_the_features_directory
    assert_equal File.join(Dir.pwd, "features/**/*.feature"), GherkinSystem.config.features
  end
end
