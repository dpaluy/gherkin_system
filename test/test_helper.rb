# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "gherkin_system"
require "minitest/autorun"
require "fileutils"
require "tmpdir"

class GherkinSystemTest < Minitest::Test
  def setup
    GherkinSystem.reset_configuration!
    %w[GHERKIN_FEATURES GHERKIN_LINE GHERKIN_TAGS].each { |key| ENV.delete(key) }
    @dirs = []
  end

  def teardown
    GherkinSystem.reset_configuration!
    @dirs.each { |dir| FileUtils.remove_entry(dir) }
    %w[GHERKIN_FEATURES GHERKIN_LINE GHERKIN_TAGS].each { |key| ENV.delete(key) }
  end

  def write_features(files)
    dir = Dir.mktmpdir
    @dirs << dir
    files.each { |name, body| File.write(File.join(dir, name), body) }
    dir
  end

  def load_features(dir, base:)
    GherkinSystem.load!(File.join(dir, "*.feature"), base: base)
  end

  def scenario_methods(klass)
    klass.public_instance_methods(false).grep(/\Atest_/).map(&:to_s).sort
  end

  def run_scenario(klass, method_name = nil)
    method_name ||= scenario_methods(klass).first
    test = klass.new(method_name)
    test.run
    test
  end
end
