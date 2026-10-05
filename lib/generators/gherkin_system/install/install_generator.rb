# frozen_string_literal: true

require "rails/generators"

module GherkinSystem
  module Generators
    # Scaffolds the loader, feature directory, and steps support directory.
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates gherkin_system loader, features, and test/support/gherkin"

      def create_loader
        template "gherkin_test.rb", "test/system/gherkin_test.rb"
      end

      def create_features_directory
        empty_directory "features"
        create_file "features/.keep", ""
      end

      def create_steps_directory
        empty_directory "test/support/gherkin"
        create_file "test/support/gherkin/.keep", ""
      end
    end
  end
end
