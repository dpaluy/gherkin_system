# frozen_string_literal: true

module GherkinSystem
  # Shared argument handling for the Rails commands.
  module Cli
    module_function

    # @param args [Array<String>]
    # @param tags [String, nil]
    # @return [Array<String>] remaining arguments
    def apply_filters!(args, tags:)
      feature = args.shift if args.first && !args.first.start_with?("-")
      apply_feature!(feature) if feature
      ENV["GHERKIN_TAGS"] = tags if tags
      args
    end

    def apply_feature!(feature)
      path, line = split_location(feature)
      ENV["GHERKIN_FEATURES"] = path
      ENV["GHERKIN_LINE"] = line if line
    end

    def split_location(feature)
      match = feature.match(/\A(.+):(\d+)\z/)
      return [match[1], match[2]] if match

      [feature, nil]
    end

    # @return [String]
    def test_file
      root = defined?(Rails) ? Rails.root : Dir.pwd
      File.join(root.to_s, GherkinSystem.config.test_file)
    end

    # @return [void]
    def prepare_test_env!
      ENV["RAILS_ENV"] = "test"
    end
  end
end
