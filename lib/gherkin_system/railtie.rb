# frozen_string_literal: true

module GherkinSystem
  # Loads the gem when Rails boots. Does not replace ApplicationSystemTestCase.
  class Railtie < Rails::Railtie
  end
end
