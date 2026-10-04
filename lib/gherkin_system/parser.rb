# frozen_string_literal: true

require "gherkin/pickles/compiler"
require "gherkin/parser"

module GherkinSystem
  # Turns a feature file into {Scenario} objects. Cucumber messages do not leave this class.
  class Parser
    # @param path [String]
    # @return [Array<Scenario>]
    def self.parse_file(path)
      parse(File.read(path), path)
    end

    # @param source_text [String]
    # @param uri [String]
    # @return [Array<Scenario>]
    def self.parse(source_text, uri)
      document = Gherkin::Parser.new.parse(source_text)
      new(document, uri).scenarios
    rescue Gherkin::ParserError => e
      raise CompilationError, "#{uri}: #{e.message}"
    end

    def initialize(document, uri)
      @document = document
      @uri = uri.to_s
      @step_lines = {}
      @step_keywords = {}
      @example_rows = {}
      @scenario_lines = {}
    end

    # @return [Array<Scenario>]
    def scenarios
      return [] unless feature

      index_children(feature.children)
      pickles.map { |pickle| build_scenario(pickle) }
    end

    private

    def feature
      @document.feature
    end

    def pickles
      source = Struct.new(:uri).new(@uri)
      generator = Cucumber::Messages::Helpers::IdGenerator::Incrementing.new
      Gherkin::Pickles::Compiler.new(generator).compile(@document, source)
    end

    def index_children(children)
      children.each do |child|
        index_children(child.rule.children) if child.rule
        index_steps(child.background.steps) if child.background
        index_scenario(child.scenario) if child.scenario
      end
    end

    def index_scenario(scenario)
      @scenario_lines[scenario.id] = scenario.location.line
      index_steps(scenario.steps)
      scenario.examples.each do |examples|
        Array(examples.table_body).each do |row|
          @example_rows[row.id] = row.cells.map(&:value)
        end
      end
    end

    def index_steps(steps)
      steps.each do |step|
        @step_lines[step.id] = step.location.line
        @step_keywords[step.id] = step.keyword.to_s.strip
      end
    end

    def build_scenario(pickle)
      Scenario.new(
        uri: @uri,
        feature_name: feature.name,
        name: pickle.name,
        tags: pickle.tags.map(&:name),
        example_values: example_values(pickle),
        line: pickle.location.line,
        scenario_line: scenario_line(pickle),
        steps: pickle.steps.map { |step| build_step(step) }
      )
    end

    def example_values(pickle)
      pickle.ast_node_ids.filter_map { |id| @example_rows[id] }.first || []
    end

    def scenario_line(pickle)
      pickle.ast_node_ids.filter_map { |id| @scenario_lines[id] }.first || pickle.location.line
    end

    def build_step(pickle_step)
      step_id = pickle_step.ast_node_ids.first
      Step.new(
        text: pickle_step.text,
        keyword: @step_keywords[step_id] || "Given",
        line: @step_lines[step_id],
        table: table_from(pickle_step),
        doc_string: doc_from(pickle_step)
      )
    end

    def table_from(pickle_step)
      table = pickle_step.argument&.data_table
      return nil unless table

      DataTable.new(table.rows.map { |row| row.cells.map(&:value) })
    end

    def doc_from(pickle_step)
      pickle_step.argument&.doc_string&.content
    end
  end
end
