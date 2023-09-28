# frozen_string_literal: true

module EdifactRails
  class Serializer
    # Treat the input a little, split the input string into segments, parse them
    def serialize(segments, with_service:)
      # Add the UNA segment

      # Serialize and join the segments
      output = segments.map { |segment| serialize_segment(segment) }
                       .join(EdifactRails::Parser::SEGMENT_SEPARATOR)

      output.insert(0, "UNA:+.? '") unless segments.first.first == "UNA" || !with_service
      output + EdifactRails::Parser::SEGMENT_SEPARATOR
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
      serialized_elements.prepend(tag).join(EdifactRails::Parser::DATA_ELEMENT_SEPARATOR)
    end

    def serialize_data_element(element)
      element.map { |component| treat_component(component) }
             .join(EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR)
    end

    # Strip, remove escape characters, convert to nil where needed, convert to integer where needed
    def treat_component(component)
      return component unless component.is_a? String

      # Prepare regex
      all_special_characters = [
        EdifactRails::Parser::SEGMENT_SEPARATOR,
        EdifactRails::Parser::DATA_ELEMENT_SEPARATOR,
        EdifactRails::Parser::COMPONENT_DATA_ELEMENT_SEPARATOR,
        EdifactRails::Parser::ESCAPE_CHARACTER
      ].join

      # If the component has escaped characters in it, prepend the escape character "+" -> "?+", "?" -> "??"
      component.gsub(/([#{Regexp.quote(all_special_characters)}])/) do |match|
        EdifactRails::Parser::ESCAPE_CHARACTER + match
      end
    end
  end
end
