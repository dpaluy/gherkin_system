# frozen_string_literal: true

require_relative "gherkin_system/version"
require_relative "gherkin_system/errors"
require_relative "gherkin_system/configuration"
require_relative "gherkin_system/data_table"
require_relative "gherkin_system/scenario"
require_relative "gherkin_system/snippet"
require_relative "gherkin_system/parameter_registry"
require_relative "gherkin_system/step_definition"
require_relative "gherkin_system/step_registry"
require_relative "gherkin_system/steps"
require_relative "gherkin_system/hooks"
require_relative "gherkin_system/tag_filter"
require_relative "gherkin_system/parser"
require_relative "gherkin_system/feature_loader"
require_relative "gherkin_system/test_class_builder"
require_relative "gherkin_system/scenario_run"
require_relative "gherkin_system/executor"
require_relative "gherkin_system/checker"
require_relative "gherkin_system/cli"

# Compiles Gherkin features into Minitest methods on the application's system test class.
#
# @example Load features
#   GherkinSystem.load!(base: ApplicationSystemTestCase)
module GherkinSystem
  class << self
    # @return [Configuration]
    def config
      @config ||= Configuration.new
    end

    # @yieldparam config [Configuration]
    # @return [void]
    def configure
      yield(config)
    end

    # Clears configuration, step definitions, hooks, and generated test classes.
    #
    # @return [void]
    def reset_configuration!
      @config = nil
      @step_registry = nil
      @parameter_registry = nil
      @hook_registry = nil
      Suite.reset!
    end

    # @param glob [String, Pathname, nil]
    # @param base [Class, nil] system test superclass. Required when config.base_test_class is unset.
    # @return [Array<Class>] generated test classes
    def load!(glob = nil, base: nil)
      test_class = base || config.base_test_class
      raise ConfigurationError, "Pass base: or set config.base_test_class" if test_class.nil?

      scenarios = TagFilter.apply(FeatureLoader.load(glob), config.tags)
      TestClassBuilder.new(test_class).build(scenarios)
    end

    # @return [StepRegistry]
    def step_registry
      @step_registry ||= StepRegistry.new(parameter_registry)
    end

    # @return [ParameterRegistry]
    def parameter_registry
      @parameter_registry ||= ParameterRegistry.new
    end

    # @return [HookRegistry]
    def hook_registry
      @hook_registry ||= HookRegistry.new
    end
  end
end

require_relative "gherkin_system/railtie" if defined?(Rails::Railtie)
