# frozen_string_literal: true

require "edifact_rails/parser"
require "edifact_rails/serializer"
require "edifact_rails/formats"
require "edifact_rails/exceptions"

module EdifactRails
  DEFAULT_SPECIAL_CHARACTERS = {
    component_data_element_seperator: ":",
    data_element_seperator: "+",
    decimal_notation: ".",
    escape_character: "?",
    segment_seperator: "'"
  }.freeze

  def self.parse(string)
    parser = EdifactRails::Parser.new
    parser.parse(string)
  end

  def self.parse_file(file_path)
    parse(File.read(file_path))
  end

  def self.special_characters(string = "")
    parser = EdifactRails::Parser.new
    parser.special_characters(string)
  end

  def self.serialize(array, with_service: true)
    serializer = EdifactRails::Serializer.new
    serializer.serialize array, with_service: with_service
  end
end
