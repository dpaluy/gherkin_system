# frozen_string_literal: true

require "cucumber/tag_expressions"

module GherkinSystem
  # One Before, After, or Around hook.
  class Hook
    # @return [Proc]
    attr_reader :block

    # @param expression [Object, nil] parsed tag expression, or nil to match every scenario
    # @param block [Proc]
    def initialize(expression, block)
      @expression = expression
      @block = block
    end

    # @param tags [Array<String>]
    # @return [Boolean]
    def applies_to?(tags)
      @expression.nil? || @expression.evaluate(tags)
    end
  end

  # Hooks registered by {Hooks}.
  class HookRegistry
    def initialize
      @hooks = { before: [], after: [], around: [] }
    end

    # @param kind [Symbol] :before, :after, or :around
    # @param tag_expression [String, nil]
    # @param block [Proc]
    # @return [Hook]
    def add(kind, tag_expression, block)
      hook = Hook.new(parse(tag_expression), block)
      @hooks.fetch(kind) << hook
      hook
    end

    # @param kind [Symbol]
    # @param tags [Array<String>]
    # @return [Array<Hook>]
    def matching(kind, tags)
      @hooks.fetch(kind).select { |hook| hook.applies_to?(tags) }
    end

    private

    def parse(expression)
      return nil if expression.nil? || expression.to_s.strip.empty?

      Cucumber::TagExpressions::Parser.new.parse(expression)
    rescue StandardError => e
      raise CompilationError, "Malformed hook tag expression #{expression.inspect}: #{e.message}"
    end
  end

  # DSL extended by hook modules.
  #
  # @example
  #   module CheckoutHooks
  #     extend GherkinSystem::Hooks
  #
  #     Before("@admin") { visit admin_root_path }
  #   end
  module Hooks
    # @param tag_expression [String, nil]
    # @return [Hook]
    def Before(tag_expression = nil, &block)
      GherkinSystem.hook_registry.add(:before, tag_expression, block)
    end

    # @param tag_expression [String, nil]
    # @return [Hook]
    def After(tag_expression = nil, &block)
      GherkinSystem.hook_registry.add(:after, tag_expression, block)
    end

    # @param tag_expression [String, nil]
    # @return [Hook]
    def Around(tag_expression = nil, &block)
      GherkinSystem.hook_registry.add(:around, tag_expression, block)
    end
  end
end
