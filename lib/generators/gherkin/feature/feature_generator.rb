# frozen_string_literal: true

require "rails/generators"

module Gherkin
  module Generators
    # Creates a Gherkin feature under features.
    class FeatureGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Creates a Gherkin feature file under features"

      def create_feature
        template "feature.feature.tt", File.join("features", "#{file_path}.feature")
      end
    end
  end
end
