# frozen_string_literal: true

require "generators/gherkin/install/install_generator"

module GherkinSystem
  module Generators
    # Keeps the original generator command available.
    class InstallGenerator < Gherkin::Generators::InstallGenerator
      source_root Gherkin::Generators::InstallGenerator.source_root
    end
  end
end
