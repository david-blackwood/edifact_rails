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
      # Remove all carraige returns, and leading and trailing whitespace
      string = string.gsub(/\r/, '').gsub(/^\s*(.*)\s*$/, '\1')

      @edi_format = detect_edi_format(string)

      # Detects special characters in the UNA segment (edifact) or ISA segment (ansix12),
      # updates special characters if so
      detect_special_characters(string)

      # Does some funky regex maniulation to handle escaped special characters
      # Ansix12 does not have escape characters, so we can skip
      string = handle_duplicate_escape_characters(string) unless @edi_format == EdifactRails::Formats::ANSIX12

      # Split the input string into segments
      segments =
        if @edi_format == EdifactRails::Formats::ANSIX12
          string.split(@special_characters[:segment_seperator])
        else
          string.split(/(?<!#{Regexp.quote(@special_characters[:escape_character])})#{Regexp.quote(@special_characters[:segment_seperator])}/)
        end

      # Drop the UNA segment, if present (we have already dealt with it in #detect_special_characters)
      segments.reject! { |s| s[0..2] == "UNA" }

      # Parse the segments
      segments.map { |segment| parse_segment(segment) }
    end

    # Given an input string, return the special characters as defined by the UNA segment
    def special_characters(string = '')
      # If no string is passed, return default edifact characters
      return EdifactRails::DEFAULT_SPECIAL_CHARACTERS if string.length == 0

      string = string.gsub(/\r/, '').gsub(/^\s*(.*)\s*$/, '\1')
      @edi_format = detect_edi_format(string)
      detect_special_characters(string)

      @special_characters
    end

    private

    def detect_edi_format(string)
      case string[0..2]
      when 'UNA', 'UNB'
        EdifactRails::Formats::EDIFACT
      when 'STX'
        EdifactRails::Formats::TRADACOMS
      when 'ISA'
        EdifactRails::Formats::ANSIX12
      else
        raise EdifactRails::UnrecognizedFormat
      end
    end

    def detect_special_characters(string)
      # Format must be EDIFACT or ANSI X12 to set custom characters
      # Tradacoms uses the defaults
      return unless [EdifactRails::Formats::EDIFACT, EdifactRails::Formats::ANSIX12].include?(@edi_format)

      # If EDIFACT, UNA tags are optional, so return if it's not present
      return if @edi_format == EdifactRails::Formats::EDIFACT && string[0..2] != "UNA"

      case @edi_format
      when EdifactRails::Formats::EDIFACT
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
        set_special_characters(
          component_data_element_seperator: string[3],
          data_element_seperator: string[4],
          decimal_notation: string[5],
          escape_character: string[6],
          segment_seperator: string[8]
        )
      when EdifactRails::Formats::ANSIX12
        # ISA segments look like this:
        # ISA*00*          *00*          *01*SENDER         *01*RECEIVER       *231014*1200*U*00401*000000001*1*P*>~
        # These are designed to always be the same number of characters, so we can use the hardcoded positions
        # The special characters are the 4th (default *, data_element_seperator),
        # 105th, 106th, 103rd, and 3rd characters
        set_special_characters(
          data_element_seperator: string[3],
          component_data_element_seperator: string[104],
          segment_seperator: string[105]
        )
      end
    end

    def set_special_characters(args = {})
      # arg keys will overwrite the defaults when present
      @special_characters = EdifactRails::DEFAULT_SPECIAL_CHARACTERS.merge(args)

      # ANSIX12 files have no escape character or decimal notation character§
      if @edi_format == EdifactRails::Formats::ANSIX12
        @special_characters.delete(:escape_character)
        @special_characters.delete(:decimal_notation)
      end
    end

    def handle_duplicate_escape_characters(string)
      # Prepare regex
      other_specials_regex = Regexp.quote(
        [
          @special_characters[:segment_seperator],
          @special_characters[:data_element_seperator],
          @special_characters[:component_data_element_seperator]
        ].join
      )

      # If there is an EVEN number of escape characters before a special character,
      # the special character is therefore unescaped.
      # Add a space between these even number of escapes, and the special character
      #
      # This means the regex logic for splitting on special characters is now consistent, since there will only ever
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
        /(?<!#{Regexp.quote(@special_characters[:escape_character])})((#{Regexp.quote(@special_characters[:escape_character])}{2})+)([#{other_specials_regex}])/,
        '\1 \3'
      )
    end

    # Split the segment into data elements, take the first as the tag, then parse the rest
    def parse_segment(segment)
      segment.chomp('')
      segment.gsub! /^\s*(.*)\s*/, '\1'

      # If the input is a tradacoms file, the segment tag will be proceeded by '=' instead of '+'
      # 'QTY=1+A:B' instead of 'QTY+1+A:B'
      # Fortunately, this is easily handled by simply changing these "="s into "+"s before the split
      if @edi_format == EdifactRails::Formats::TRADACOMS && segment.length >= 4
        segment[3] = @special_characters[:data_element_seperator]
      end

      # Segments are made up of data elements
      data_elements =
        if @edi_format == EdifactRails::Formats::ANSIX12
          segment.split(@special_characters[:data_element_seperator])
        else
          segment.split(/(?<!#{Regexp.quote(@special_characters[:escape_character])})#{Regexp.quote(@special_characters[:data_element_seperator])}/)
        end

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
        if @edi_format == EdifactRails::Formats::ANSIX12
          element.split(@special_characters[:component_data_element_seperator])
        else
          element.split(/(?<!#{Regexp.quote(@special_characters[:escape_character])})#{Regexp.quote(@special_characters[:component_data_element_seperator])}/)
        end

      components.map { |component| treat_component(component) }
    end

    # Strip, remove escape characters, convert to nil where needed, convert to integer where needed
    def treat_component(component)
      # Remove surrounding whitespace
      component.strip!

      # Prepare regex
      all_special_characters_string = [
        @special_characters[:segment_seperator],
        @special_characters[:data_element_seperator],
        @special_characters[:component_data_element_seperator],
        @special_characters[:escape_character]
      ].join

      unless @edi_format == EdifactRails::Formats::ANSIX12
        # If the component has escaped characters in it, remove the escape character and return the character as is
        # "?+" -> "+", "??" -> "?"
        component.gsub!(/#{Regexp.quote(@special_characters[:escape_character])}([#{Regexp.quote(all_special_characters_string)}])/, '\1')
      end

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
