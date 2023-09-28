# frozen_string_literal: true

require "edifact_rails/parser"
require "edifact_rails/serializer"

module EdifactRails
  def self.parse(string)
    parser = EdifactRails::Parser.new
    parser.parse string
  end

  def self.parse_file(file_path)
    parse(File.read(file_path).split("\n").join)
  end

  def self.serialize(array, with_service: true)
    serializer = EdifactRails::Serializer.new
    serializer.serialize array, with_service: with_service
  end
end
