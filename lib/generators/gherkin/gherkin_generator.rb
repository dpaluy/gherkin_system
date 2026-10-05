# frozen_string_literal: true

require "generators/gherkin/install/install_generator"

module Gherkin
  module Generators
    # Runs the install generator for the bare gherkin command.
    class GherkinGenerator < InstallGenerator
      source_root InstallGenerator.source_root
    end
  end
end
