# frozen_string_literal: true

module GherkinSystem
  # One executable Pickle.
  Scenario = Data.define(
    :uri,
    :feature_name,
    :name,
    :tags,
    :example_values,
    :line,
    :scenario_line,
    :steps
  ) do
    # @return [String] Minitest-facing scenario label
    def test_name
      label = "#{feature_name}: #{name}"
      return label if example_values.empty?

      "#{label} [#{example_values.join(", ")}]"
    end

    # @param number [Integer]
    # @return [Boolean]
    def covers_line?(number)
      lines.include?(number)
    end

    # @return [Array<Integer>]
    def lines
      [line, scenario_line, *steps.map(&:line)].compact.uniq
    end
  end

  # One step inside a {Scenario}.
  Step = Data.define(:text, :keyword, :line, :table, :doc_string)
end
