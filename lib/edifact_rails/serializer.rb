# frozen_string_literal: true

module EdifactRails
  class Serializer
    # Treat the input a little, split the input string into segments, parse them
    def serialize(segments, with_service:)
      # Add the UNA segment

      # Serialize and join the segments
      output = segments.map { |segment| serialize_segment(segment) }
                       .join(EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:segment_seperator])

      output.insert(0, "UNA:+.? '") unless segments.first.first == "UNA" || !with_service
      output + EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:segment_seperator]
    end

    private

    # Serialize the data elements and join them to serialize the segment
    def serialize_segment(segment)
      return if segment.empty?

      # Get the tag
      tag = segment.first
      data_elements = segment[1..]

      # Serialize the data elements
      serialized_elements = data_elements.map { |element| serialize_data_element(element) }

      # Join tag and data elements
      serialized_elements.prepend(tag).join(EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:data_element_seperator])
    end

    def serialize_data_element(element)
      element.map { |component| treat_component(component) }
             .join(EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:component_data_element_seperator])
    end

    # Strip, remove escape characters, convert to nil where needed, convert to integer where needed
    def treat_component(component)
      return component unless component.is_a? String

      # Prepare regex
      all_special_characters = [
        EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:segment_seperator],
        EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:data_element_seperator],
        EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:component_data_element_seperator],
        EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:escape_character]
      ].join

      # If the component has escaped characters in it, prepend the escape character "+" -> "?+", "?" -> "??"
      component.gsub(/([#{Regexp.quote(all_special_characters)}])/) do |match|
        EdifactRails::DEFAULT_SPECIAL_CHARACTERS[:escape_character] + match
      end
    end
  end
end
