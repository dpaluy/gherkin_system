# frozen_string_literal: true

require "generators/gherkin/feature/feature_generator"

module GherkinSystem
  module Generators
    # Keeps the original generator command available.
    class FeatureGenerator < Gherkin::Generators::FeatureGenerator
      source_root Gherkin::Generators::FeatureGenerator.source_root
    end
  end
end
