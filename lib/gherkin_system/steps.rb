# frozen_string_literal: true

module GherkinSystem
  # DSL extended by step-definition modules.
  #
  # @example
  #   module AuthenticationSteps
  #     extend GherkinSystem::Steps
  #
  #     Given("I am signed in") { sign_in users(:customer) }
  #   end
  module Steps
    # @param pattern [String, Regexp]
    # @return [StepDefinition]
    def Given(pattern, &)
      GherkinSystem.step_registry.register(pattern, &)
    end

    alias When Given
    alias Then Given
    alias And Given
    alias But Given

    # @param name [String]
    # @param regexp [Regexp, String]
    # @param type [Class]
    # @param transformer [Proc]
    # @return [void]
    def ParameterType(name:, regexp:, transformer:, type: String, prefer_for_regexp_match: false)
      GherkinSystem.parameter_registry.define(
        name: name,
        regexp: regexp,
        transformer: transformer,
        type: type,
        prefer_for_regexp_match: prefer_for_regexp_match
      )
    end
  end
end
