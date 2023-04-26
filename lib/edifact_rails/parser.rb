# frozen_string_literal: true

require "byebug"

module EdifactRails
  class Parser
    SEGMENT_SEPARATOR = "'"
    DATA_ELEMENT_SEPARATOR = "+"
    COMPONENT_DATA_ELEMENT_SEPARATOR = ":"
    ESCAPE_CHARACTER = "?"

    # Input is one large string, made up of multiple segments
    def parse(input)
      parsed_segments = []

      # If there is an EVEN number of escape characters before a special character,
      # the special character is therefore unescaped.
      # Add a space between these even number of escapes, and the special character
      #
      # This means the regex logic for #splitting on special characters is now consistent, since there will only ever
      # be either 1 or 0 escape characters before every unescaped special character.
      #
      # We have to do this because we can't negative lookbehind for 'an even number of escape characters' since
      # lookbehinds have to be fixed length.
      #
      # The added space, which is now at the boundry of a component,
      # will get cut by the #strip! in treat_component eventually
      #
      # "LIN+even????+123" => '+' is not escaped, gsub'ed => "even???? +123" => parsed => ['LIN', ['even??'], [123]]
      # "LIN+odd???+123" => '+' is escaped, not gsub'ed => "odd???+123" => parsed => ['LIN', ['odd?+123']]

      # Prepare for regex
      esc_rx = Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)
      other_specials_rx = Regexp.quote(
        [
          EdifactRails::Parser::SEGMENT_SEPARATOR,
          EdifactRails::Parser::DATA_ELEMENT_SEPARATOR,
          EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR
        ].join
      )

      input = input.gsub(/(?<!#{esc_rx})((#{esc_rx}{2})+)([#{other_specials_rx}])/, '\1 \3')

      segments = input.split(
        /(?<!#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::SEGMENT_SEPARATOR)}/
      )

      segments.reject! { |s| s[0..2] == "UNA" }

      segments.map { |segment| parse_segment(segment) }
    end

    private

    # Segments are split into data element, where the first data element is the 'tag'
    def parse_segment(segment)
      # Segments are made up of data elements
      data_elements = segment.split(
        /(?<!#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::DATA_ELEMENT_SEPARATOR)}/
      )

      parsed_segment = []

      # The first element is the tag, pop it off
      parsed_segment.push(data_elements.shift) if data_elements.any?

      parsed_segment.concat(data_elements.map { |element| parse_data_element(element) })
    end

    # Data elements are split into component data elements
    def parse_data_element(element)
      components = element.split(
        /(?<!#{Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)})#{Regexp.quote(EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR)}/
      )

      components.map { |component| treat_component(component) }
    end

    # Strip, remove escape characters, convert to nil where needed, convert to integer where needed
    def treat_component(component)
      # Remove surrounding whitespace
      component.strip!

      # Prepare for regex
      all_special_characters = [
        EdifactRails::Parser::SEGMENT_SEPARATOR,
        EdifactRails::Parser::DATA_ELEMENT_SEPARATOR,
        EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR,
        EdifactRails::Parser::ESCAPE_CHARACTER
      ].join

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

      component
    end
  end
end
