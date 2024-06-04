# frozen_string_literal: true

module EdifactRails
  class Parser
    def initialize
      # Set default separators
      # They can be overridden by the UNA segment in #detect_special_characters
      set_special_characters
    end

    # Treat the input, split the input string into segments, parse those segments
    def parse(string)
      # Trim newlines and excess spaces around those newlines
      string = string.gsub(/\s*\n\s*/, "")

      # Check for UNA segment, update special characters if so
      detect_special_characters(string)

      # Does some funky regex maniulation to handle escaped special characters
      string = treat_input(string)

      # Split the input string into segments
      segments = string.split(/(?<!#{Regexp.quote(@escape_character)})#{Regexp.quote(@segment_seperator)}/)

      # Detect if the input is a tradacoms file
      @is_tradacoms = segments.map { |s| s[3] }.uniq == ["="]

      # Drop the UNA segment, if present (we have already dealt with it in #detect_special_characters)
      segments.reject! { |s| s[0..2] == "UNA" }

      # Parse the segments
      segments.map { |segment| parse_segment(segment) }
    end

    # Given an input string, return the special characters as defined by the UNA segment
    # If no UNA segment is present, returns the default special characters
    def una_special_characters(string)
      detect_special_characters(string)

      {
        component_data_element_seperator: @component_data_element_seperator,
        data_element_seperator: @data_element_seperator,
        decimal_notation: @decimal_notation,
        escape_character: @escape_character,
        segment_seperator: @segment_seperator
      }
    end

    private

    def set_special_characters(
      component_data_element_seperator =
        EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:component_data_element_seperator],
      data_element_seperator = EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:data_element_seperator],
      decimal_notation = EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:decimal_notation],
      escape_character = EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:escape_character],
      segment_seperator = EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:segment_seperator]
    )
      # Set the special characters
      @component_data_element_seperator = component_data_element_seperator
      @data_element_seperator = data_element_seperator
      @decimal_notation = decimal_notation
      @escape_character = escape_character
      @segment_seperator = segment_seperator
    end

    def detect_special_characters(string)
      # UNA tags must be at the start of the input otherwise they are ignored
      return unless string[0..2] == "UNA"

      # UNA segments look like this:
      #
      # UNA:+.? '
      #
      # UNA followed by 6 special characters which are, in order:
      # 1. Component data element separator
      # 2. Data element separator
      # 3. Decimal notation (must be . or ,)
      # 4. Release character (aka escape character)
      # 5. Reserved for future use, so always a space for now
      # 6. Segment terminator
      set_special_characters(string[3], string[4], string[5], string[6], string[8])
    end

    def treat_input(string)
      # Prepare regex
      other_specials_rx = Regexp.quote(
        [
          @segment_seperator,
          @data_element_seperator,
          @component_data_element_seperator
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
      string.gsub(
        /(?<!#{Regexp.quote(@escape_character)})((#{Regexp.quote(@escape_character)}{2})+)([#{other_specials_rx}])/,
        '\1 \3'
      )
    end

    # Split the segment into data elements, take the first as the tag, then parse the rest
    def parse_segment(segment)
      # If the input is a tradacoms file, the segment tag will be proceeded by '=' instead of '+'
      # 'QTY=1+A:B' instead of 'QTY+1+A:B'
      # Fortunately, this is easily handled by simply changing these "="s into "+"s before the split
      segment[3] = @data_element_seperator if @is_tradacoms && segment.length >= 4

      # Segments are made up of data elements
      data_elements = segment.split(/(?<!#{Regexp.quote(@escape_character)})#{Regexp.quote(@data_element_seperator)}/)

      # The first element is the tag, pop it off
      parsed_segment = []
      parsed_segment.push(data_elements.shift) if data_elements.any?

      # Parse the data elements
      parsed_segment.concat(data_elements.map { |element| parse_data_element(element) })
    end

    # Split the data elements into component data elements, and treat them
    def parse_data_element(element)
      # Split data element into components
      components =
        element.split(/(?<!#{Regexp.quote(@escape_character)})#{Regexp.quote(@component_data_element_seperator)}/)

      components.map { |component| treat_component(component) }
    end

    # Strip, remove escape characters, convert to nil where needed, convert to integer where needed
    def treat_component(component)
      # Remove surrounding whitespace
      component.strip!

      # Prepare regex
      all_special_characters_string = [
        @segment_seperator,
        @data_element_seperator,
        @component_data_element_seperator,
        @escape_character
      ].join

      # If the component has escaped characters in it, remove the escape character and return the character as is
      # "?+" -> "+", "??" -> "?"
      component.gsub!(/#{Regexp.quote(@escape_character)}([#{Regexp.quote(all_special_characters_string)}])/, '\1')

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
