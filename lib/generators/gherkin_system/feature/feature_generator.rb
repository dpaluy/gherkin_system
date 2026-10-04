# frozen_string_literal: true

require "rails/generators"

module GherkinSystem
  module Generators
    # Creates a Gherkin feature under features/system.
    class FeatureGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Creates a Gherkin feature file under features/system"

      def create_feature
        template "feature.feature.tt", File.join("features/system", "#{file_path}.feature")
      end
    end
  end
end
