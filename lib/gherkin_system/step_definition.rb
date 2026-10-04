# frozen_string_literal: true

require "cucumber/cucumber_expressions/cucumber_expression"
require "cucumber/cucumber_expressions/regular_expression"

module GherkinSystem
  # One registered Given/When/Then block.
  class StepDefinition
    # @return [String, Regexp]
    attr_reader :pattern

    # @return [Proc]
    attr_reader :block

    # @return [Array(String, Integer)]
    attr_reader :location

    # @param pattern [String, Regexp]
    # @param block [Proc]
    # @param expression [Object]
    # @param location [Array(String, Integer)]
    def initialize(pattern, block, expression, location)
      @pattern = pattern
      @block = block
      @expression = expression
      @location = location
    end

    # @param text [String]
    # @return [Boolean]
    def matches?(text)
      !match(text).nil?
    end

    # @param text [String]
    # @param test [Object]
    # @return [Array]
    def captures(text, test)
      match(text).map { |argument| argument.value(test) }
    end

    # @return [String]
    def location_label
      "#{location[0]}:#{location[1]}"
    end

    private

    def match(text)
      @expression.match(text)
    end
  end
end
