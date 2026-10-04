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
      selected = filter_line(filter_path(selected))
      ensure_matches!(selected)
      selected
    end

    private

    def files
      requested = ENV.fetch("GHERKIN_FEATURES", nil)
      return [requested] if requested && File.file?(requested)

      paths = Dir.glob(@glob)
      return paths if requested.nil? || requested.empty?

      paths.select { |path| path_match?(path, requested) }
    end

    def filter_path(scenarios)
      requested = ENV.fetch("GHERKIN_FEATURES", nil)
      return scenarios if requested.nil? || requested.empty?

      scenarios.select { |scenario| path_match?(scenario.uri, requested) }
    end

    def filter_line(scenarios)
      line = ENV.fetch("GHERKIN_LINE", nil)
      return scenarios if line.nil? || line.empty?

      number = Integer(line)
      scenarios.select { |scenario| scenario.covers_line?(number) }
    end

    def path_match?(path, requested)
      expanded_path = File.expand_path(path)
      expanded_requested = File.expand_path(requested)
      return true if expanded_path == expanded_requested

      return false unless File.directory?(expanded_requested)

      prefix = expanded_requested.end_with?("/") ? expanded_requested : "#{expanded_requested}/"
      expanded_path.start_with?(prefix)
    end

    def ensure_matches!(scenarios)
      return if scenarios.any?
      return unless filtered?

      raise ConfigurationError, "No scenarios matched #{filter_description}"
    end

    def filtered?
      feature = ENV.fetch("GHERKIN_FEATURES", nil)
      line = ENV.fetch("GHERKIN_LINE", nil)
      !(feature.nil? || feature.empty?) || !(line.nil? || line.empty?)
    end

    def filter_description
      feature = ENV.fetch("GHERKIN_FEATURES", nil)
      line = ENV.fetch("GHERKIN_LINE", nil)
      return "#{feature}:#{line}" if feature && line
      return feature if feature && !feature.empty?

      "line #{line}"
    end
  end
end
