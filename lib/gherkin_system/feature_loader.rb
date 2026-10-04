# frozen_string_literal: true

module GherkinSystem
  # Discovers feature files and applies path and line filters from the environment.
  class FeatureLoader
    # @param glob [String, Pathname, nil]
    # @return [Array<Scenario>]
    def self.load(glob = nil)
      new(glob || GherkinSystem.config.features).scenarios
    end

    # @param glob [String, Pathname]
    def initialize(glob)
      @glob = glob.to_s
    end

    # @return [Array<Scenario>]
    def scenarios
      selected = files.flat_map { |path| Parser.parse_file(path) }
      filter_line(filter_path(selected))
    end

    private

    def files
      requested = ENV.fetch("GHERKIN_FEATURES", nil)
      return [requested] if requested && File.file?(requested)

      paths = Dir.glob(@glob)
      return paths if requested.nil? || requested.empty?

      expanded = File.expand_path(requested)
      paths.select { |path| File.expand_path(path) == expanded }
    end

    def filter_path(scenarios)
      requested = ENV.fetch("GHERKIN_FEATURES", nil)
      return scenarios if requested.nil? || requested.empty?

      expanded = File.expand_path(requested)
      scenarios.select { |scenario| File.expand_path(scenario.uri) == expanded }
    end

    def filter_line(scenarios)
      line = ENV.fetch("GHERKIN_LINE", nil)
      return scenarios if line.nil? || line.empty?

      number = Integer(line)
      scenarios.select { |scenario| scenario.covers_line?(number) }
    end
  end
end
