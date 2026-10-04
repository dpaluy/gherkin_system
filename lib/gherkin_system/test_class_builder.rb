# frozen_string_literal: true

require "digest"

module GherkinSystem
  # Namespace for generated test classes.
  module Suite
    # Removes generated classes. Used by tests.
    #
    # @return [void]
    def self.reset!
      constants(false).each { |name| remove_const(name) }
    end
  end

  # Defines one Minitest class per feature file.
  class TestClassBuilder
    # @param base [Class]
    def initialize(base)
      @base = base
    end

    # @param scenarios [Array<Scenario>]
    # @return [Array<Class>]
    def build(scenarios)
      scenarios.group_by(&:uri).map { |uri, group| build_class(uri, group) }
    end

    private

    def build_class(uri, scenarios)
      klass = Class.new(@base)
      assign_constant(klass, scenarios.first.feature_name, uri)
      include_step_modules(klass)
      record_scenarios(klass, define_tests(klass, scenarios))
      define_preflight(klass)
      klass
    end

    def assign_constant(klass, feature_name, uri)
      name = constant_name(feature_name, uri)
      Suite.send(:remove_const, name) if Suite.const_defined?(name, false)
      Suite.const_set(name, klass)
    end

    def constant_name(feature_name, uri)
      stem = feature_name.to_s.scan(/[A-Za-z0-9]+/).map(&:capitalize).join
      stem = "Feature#{stem}" unless stem.match?(/\A[A-Z]/)
      suffix = Digest::SHA1.hexdigest(uri.to_s)[0, 6]
      "#{stem}#{suffix}Test"
    end

    def include_step_modules(klass)
      GherkinSystem.config.step_modules.each { |mod| klass.include(mod) }
    end

    def define_tests(klass, scenarios)
      scenarios.each_with_index.to_h do |scenario, index|
        method_name = method_name_for(scenario, index)
        klass.define_method(method_name) { GherkinSystem::Executor.call(self) }
        [method_name, scenario]
      end
    end

    def method_name_for(scenario, index)
      slug = scenario.test_name.gsub(/[^A-Za-z0-9]+/, "_").gsub(/\A_|_\z/, "")
      slug = "scenario" if slug.empty?
      "test_#{slug}_#{index}"
    end

    def record_scenarios(klass, scenarios_by_method)
      klass.define_singleton_method(:gherkin_scenarios) { scenarios_by_method }
    end

    def define_preflight(klass)
      klass.define_method(:before_setup) do
        GherkinSystem::Executor.validate!(self) if GherkinSystem.config.strict
        super() if defined?(super)
      end
    end
  end
end
