# frozen_string_literal: true

require "byebug"

module EdifactRails
  class Parser
    SEGMENT_SEPARATOR = "'"
    DATA_ELEMENT_SEPARATOR = "+"
    COMPONENT_DATA_ELEMENT_SEPARATOR = ":"
    ESCAPE_CHARACTER = "?"

    # Treat the input a little, split the input into segments, parse them
    def parse(input)
      # Trim newlines
      input = input.gsub(/\s*\n\s*/, "")

      # Prepare regex
      esc_rx = Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)
      seg_sep_rx = Regexp.quote(EdifactRails::Parser::SEGMENT_SEPARATOR)
      other_specials_rx = Regexp.quote(
        [
          EdifactRails::Parser::SEGMENT_SEPARATOR,
          EdifactRails::Parser::DATA_ELEMENT_SEPARATOR,
          EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR
        ].join
      )

      # If there is an EVEN number of escape characters before a special character,
      # the special character is therefore unescaped.
      # Add a space between these even number of escapes, and the special character
      #
      # This means the regex logic for #splitting on special characters is now consistent, since there will only ever
      # be either 0 or 1 escape characters before every special character.
      #
      # We have to do this because we can't negative lookbehind for 'an even number of escape characters' since
      # lookbehinds have to be fixed length.
      #
      # The added space, which is now at the boundry of a component,
      # will get cut by the #strip! in #treat_component eventually
      #
      # I must admit this kind of thing is why you should use an actual parser instead of regex for, you know, parsing
      #
      # "LIN+even????+123" => '+' is not escaped, gsub'ed => "even???? +123" => parsed => ['LIN', ['even??'], [123]]
      # "LIN+odd???+123" => '+' is escaped, not gsub'ed => "odd???+123" => parsed => ['LIN', ['odd?+123']]
      input = input.gsub(/(?<!#{esc_rx})((#{esc_rx}{2})+)([#{other_specials_rx}])/, '\1 \3')

      # Split the input into segments
      segments = input.split(/(?<!#{esc_rx})#{seg_sep_rx}/)

      # Drop the UNA segment
      segments.reject! { |s| s[0..2] == "UNA" }

      # Parse the segments
      segments.map { |segment| parse_segment(segment) }
    end

    private

    # Split the segment into data elements, take the first as the tag, then parse the rest
    def parse_segment(segment)
      # Prepare regex
      esc_rx = Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)
      de_sep_rx = Regexp.quote(EdifactRails::Parser::DATA_ELEMENT_SEPARATOR)

      # Segments are made up of data elements
      data_elements = segment.split(/(?<!#{esc_rx})#{de_sep_rx}/)

      # The first element is the tag, pop it off
      parsed_segment = []
      parsed_segment.push(data_elements.shift) if data_elements.any?

      # Parse the data elements
      parsed_segment.concat(data_elements.map { |element| parse_data_element(element) })
    end

    # Split the data elements into component data elements, and treat them
    def parse_data_element(element)
      # Prepare regex
      esc_rx = Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)
      cde_sep_rx = Regexp.quote(EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR)

      # Split data element into components
      components = element.split(/(?<!#{esc_rx})#{cde_sep_rx}/)

      components.map { |component| treat_component(component) }
    end

    # Strip, remove escape characters, convert to nil where needed, convert to integer where needed
    def treat_component(component)
      # Remove surrounding whitespace
      component.strip!

      # Prepare regex
      esc_rx = Regexp.quote(EdifactRails::Parser::ESCAPE_CHARACTER)
      all_special_characters = [
        EdifactRails::Parser::SEGMENT_SEPARATOR,
        EdifactRails::Parser::DATA_ELEMENT_SEPARATOR,
        EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR,
        EdifactRails::Parser::ESCAPE_CHARACTER
      ].join

      # If the component has escaped characters in it, remove the escape character and return the character as is
      # "?+" -> "+", "??" -> "?"
      component.gsub!(/#{esc_rx}([#{Regexp.quote(all_special_characters)}])/, '\1')

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
