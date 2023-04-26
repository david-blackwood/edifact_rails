# frozen_string_literal: true

require "edifact_rails/parser"

module EdifactRails
  def self.parse(string)
    parser = EdifactRails::Parser.new
    parser.parse string
  end

  def self.parse_file(file_path)
    parse(File.read(file_path).split("\n").join)
  end
end
