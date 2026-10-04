# frozen_string_literal: true

require "rails/command"
require "gherkin_system"

module Rails
  module Command
    # Facade over `bin/rails test`. Subcommands are methods, matching `test:system`.
    class GherkinCommand < Base
      class_option :tags, type: :string, desc: "Cucumber tag expression"

      desc "gherkin [PATH]", "Run Gherkin system tests"
      def perform(*args)
        prepare!(args)
        Rails::Command.invoke("test", [GherkinSystem::Cli.test_file, *args])
      end

      desc "check [PATH]", "Validate Gherkin features without a browser"
      def check(*args)
        prepare!(args)
        load_definitions
        report(GherkinSystem::Checker.call)
      end

      desc "list [PATH]", "List compiled Gherkin scenarios"
      def list(*args)
        prepare!(args)
        scenarios.each { |scenario| puts scenario_line(scenario) }
      end

      private

      def prepare!(args)
        GherkinSystem::Cli.prepare_test_env!
        GherkinSystem::Cli.apply_filters!(args, tags: options[:tags])
        boot_application!
      end

      def load_definitions
        test_dir = Rails.root.join("test").to_s
        $LOAD_PATH.unshift(test_dir) unless $LOAD_PATH.include?(test_dir)
        path = GherkinSystem::Cli.test_file
        raise GherkinSystem::ConfigurationError, "Missing #{path}" unless File.exist?(path)

        require path
      rescue GherkinSystem::Error => e
        warn e.message
        exit!(1)
      end

      def report(result)
        io = result.ok? ? $stdout : $stderr
        io.puts(result.ok? ? "Gherkin check passed" : result.report)
        io.flush
        exit!(result.ok? ? 0 : 1)
      end

      def scenarios
        loaded = GherkinSystem::FeatureLoader.load
        GherkinSystem::TagFilter.apply(loaded, GherkinSystem.config.tags)
      end

      def scenario_line(scenario)
        "#{scenario.uri}:#{scenario.line} #{scenario.test_name}"
      end
    end
  end
end
