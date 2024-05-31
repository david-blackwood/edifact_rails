# frozen_string_literal: true

require "edifact_rails/parser"

module EdifactRails
  DEFAULT_SPECIAL_CHARACTERS = {
    component_data_element_seperator: ":",
    data_element_seperator: "+",
    escape_character: "?",
    segment_seperator: "'"
  }.freeze

  def self.parse(string)
    parser = EdifactRails::Parser.new
    parser.parse string
  end

  def self.parse_file(file_path)
    parse(File.read(file_path).split("\n").join)
  end
end
