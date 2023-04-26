# frozen_string_literal: true

require "byebug"

module EdifactRails
  class Parser
    SEGMENT_SEPARATOR = "'"
    DATA_ELEMENT_SEPARATOR = "+"
    COMPONENT_DATA_ELEMENT_SEPARATOR = ":"
    ESCAPE_CHARACTER = "?"

    def parse(string)
      parse_input(string)
    end

    def parse_file(file_path)
      parse_input(File.read(file_path).split("\n").join)
    end

    private

    # The input is one large string, split into segments
    def parse_input(input)
      parsed_segments = []

      # If there is an EVEN number of escape characters before another special character, the special character is therefore unescaped.
      # Add a space between these even number of escapes, and the special character
      # This means the regex logic for #splitting on special characters is now consistent, since we now know that if there
      # is an escape character before the special character, it should definately be respected
      # We have to do this because we can't negative lookbehind for 'an even number of escape characters' since
      # lookbehinds have to be fixed length.
      # The added space, which is now at the boundry of a component,
      # will get cut by the #strip! in parse_component eventually

      # "LIN+even????+123" => '+' is not escaped, gsub'ed => "even???? +123" => parsed => ['LIN', ['even??'], [123]]
      # "LIN+odd???+123" => '+' is escaped, not gsub'ed => "odd???+123" => parsed => ['LIN', ['odd?+123']]

      # Making the regex more readable
      escape = Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)
      other_specials = Regexp.quote(
        [
          EdifactRails::Parser::SEGMENT_SEPARATOR,
          EdifactRails::Parser::DATA_ELEMENT_SEPARATOR,
          EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR
        ].join
      )

      input = input.gsub(/(?<!#{escape})((#{escape}{2})+)([#{other_specials}])/, '\1 \3')

      segments = input.split(
        /(?<!#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::SEGMENT_SEPARATOR)}/
      )

      segments.reject! { |s| s[0..2] == "UNA" }

      segments.each do |segment|
        parsed_segments.push parse_segment(segment)
      end

      parsed_segments
    end

    # Segments are split into data element, where the first data element is the 'tag'
    def parse_segment(segment)
      # Segments are made up of data elements
      data_elements = segment.split(
        /(?<!#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::DATA_ELEMENT_SEPARATOR)}/
      )

      parsed_segment = []

      # The first element is the tag, pop it off
      parsed_segment.push(data_elements.shift) if data_elements.any?

      data_elements.each do |cell|
        parsed_segment.push parse_data_element(cell)
      end

      parsed_segment
    end

    # Data elements are split into component data elements
    def parse_data_element(element)
      parsed_element = []

      components = element.split(
        /(?<!#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR)}/
      )

      all_special_characters = [
        EdifactRails::Parser::SEGMENT_SEPARATOR,
        EdifactRails::Parser::DATA_ELEMENT_SEPARATOR,
        EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR,
        EdifactRails::Parser::ESCAPE_CHARACTER
      ].join

      components.each do |component|
        parsed_element.push treat_component(component)
      end

      parsed_element
    end

    # Strip, remove escape characters, convert to nil where needed, convert to integer where needed
    def treat_component(component)
      # Remove surrounding whitespace
      component.strip!

      # If the component has escaped characters in it, remove the escape character and return the character as is
      # "?+" -> "+", "??" -> "?"
      component.gsub!(
        /#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)}([#{Regexp.quote(all_special_characters)}])/,
        '\1'
      )

      # Convert empty strings to nils
      component = nil if component.empty?

      # Convert the component to integer if it is one
      # "1" -> 1
      # "-123" -> -123
      # "0350" -> "0350"
      component = component.to_i if component.to_i.to_s == component
    end
  end
end
