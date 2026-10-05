# frozen_string_literal: true

require "generators/gherkin/steps/steps_generator"

module GherkinSystem
  module Generators
    # Keeps the original generator command available.
    class StepsGenerator < Gherkin::Generators::StepsGenerator
      source_root Gherkin::Generators::StepsGenerator.source_root
    end
  end
end
