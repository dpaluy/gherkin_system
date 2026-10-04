# frozen_string_literal: true

module GherkinSystem
  # Global settings for feature discovery and generated tests.
  class Configuration
    # @return [Array<Module>] modules included into generated test classes
    attr_reader :step_modules

    # @return [Class, nil] superclass for generated tests
    # @return [Boolean] when true, undefined steps fail before the driver starts
    # @return [String] Rails test file that calls {.load!}
    attr_accessor :base_test_class, :strict, :test_file

    attr_writer :features

    def initialize
      @step_modules = []
      @tags_set = false
      @strict = true
      @test_file = "test/system/gherkin_test.rb"
    end

    # @return [String] glob of feature files
    def features
      @features ||= default_features
    end

    # Tag expression used when compiling. Unset values follow ENV["GHERKIN_TAGS"].
    #
    # @return [String, nil]
    def tags
      return @tags if @tags_set

      ENV.fetch("GHERKIN_TAGS", nil)
    end

    # @param value [String, nil]
    # @return [void]
    def tags=(value)
      @tags_set = true
      @tags = value
    end

    # Include helper methods from a step module into generated test classes.
    #
    # @param mod [Module]
    # @return [void]
    def include_steps(mod)
      @step_modules << mod
    end

    private

    def default_features
      File.join(root.to_s, "features/system/**/*.feature")
    end

    def root
      return Rails.root if defined?(Rails) && Rails.respond_to?(:root) && Rails.root

      Dir.pwd
    end
  end
end
