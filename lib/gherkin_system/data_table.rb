# frozen_string_literal: true

module GherkinSystem
  # Cucumber-compatible data table passed to a step block.
  class DataTable
    # @param rows [Array<Array<String>>]
    def initialize(rows)
      @rows = rows.map { |row| row.map(&:to_s) }
    end

    # @return [Array<Array<String>>] every row, including the header
    def raw
      @rows
    end

    # @return [Array<Hash{String => String}>] body rows keyed by the header
    def hashes
      header, *body = @rows
      return [] if header.nil?

      body.map { |row| header.zip(row).to_h }
    end
  end
end
