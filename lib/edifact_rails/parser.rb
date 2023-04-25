# frozen_string_literal: true

module EdifactRails
  class Parser
    SEGMENT_SEPARATOR = "'"
    DATA_ELEMENT_SEPARATOR = "+"
    COMPONENT_DATA_ELEMENT_SEPARATOR = ":"
    ESCAPE_CHARACTER = "?"

    def parse(string)
      result = []

      # This fancy regex means
      # "Don't match escaped characters (but do if the escape character itself is escaped)"
      segments = string.split(
        /(?<!(?<!#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::SEGMENT_SEPARATOR)}/
      )

      segments.each do |segment|
        result.push parse_segment(segment)
      end

      result
    end

    def parse_file
      File.foreach(file_path) do |line|
        puts line
      end
    end

    private

    def parse_segment(segment)
      # Segments are made up of data elements
      data_elements = segment.split(
        /(?<!(?<!#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::DATA_ELEMENT_SEPARATOR)}/
      )

      # The first element is the tag, pop it off
      parsed_segment = [data_elements.shift]

      data_elements.each do |cell|
        parsed_segment.push parse_data_element(cell)
      end

      parsed_segment
    end

    def parse_data_element(element)
      parsed_element = []

      components = element.split(
        /(?<!(?<!#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR)}/
      )

      all_special_characters = [
        EdifactRails::Parser::SEGMENT_SEPARATOR,
        EdifactRails::Parser::DATA_ELEMENT_SEPARATOR,
        EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR,
        EdifactRails::Parser::ESCAPE_CHARACTER
      ].join

      components.each do |component|
        component = component.chomp

        # If the component has escaped characters in it, remove the escape character and return the character as is
        # "?+" -> "+"
        # "??" -> "?"
        component.gsub!(
          /#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)}([#{Regexp.quote(all_special_characters)}])/,
          '\1'
        )

        # Convert the component to integer if it is one
        # "1" -> 1
        # "-123" -> -123
        # "0350" -> "0350"
        component = component.to_i if component.to_i.to_s == component

        parsed_element.push component
      end

      parsed_element
    end
  end
end
