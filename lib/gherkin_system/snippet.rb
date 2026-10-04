# frozen_string_literal: true

module GherkinSystem
  # Builds a step-definition snippet for an undefined step.
  module Snippet
    module_function

    # @param step [Step]
    # @return [String]
    def for(step)
      pattern, names = pattern_for(step.text)
      args = names.empty? ? "" : " |#{names.join(", ")}|"
      "#{step.keyword}(\"#{pattern}\") do#{args}\n  pending\nend"
    end

    def pattern_for(text)
      names = []
      pattern = text.gsub(/"[^"]*"|'[^']*'/) { names << "string" and "{string}" }
      pattern = pattern.gsub(/\b\d+\b/) { names << "int" and "{int}" }
      [pattern, names]
    end
  end
end
