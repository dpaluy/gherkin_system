# frozen_string_literal: true

require "rails/generators"

module GherkinSystem
  module Generators
    # Creates a step definition module under test/support/gherkin.
    class StepsGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Creates a gherkin_system steps module under test/support/gherkin"

      def create_steps
        template "steps.rb.tt", File.join("test/support/gherkin", "#{file_path}_steps.rb")
      end

      def remind_loader_wiring
        say "Remember to require and include #{steps_module_name} in test/system/gherkin_test.rb", :green
      end

      private

      def steps_module_name
        "#{class_name}Steps"
      end
    end
  end
end
