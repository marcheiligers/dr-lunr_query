module LunrQuery
  # Composite key for field/document references
  #
  # Serializes to format: "fieldName/docRef"
  # Used as keys in field vector storage.
  class FieldRef
    attr_reader :doc_ref, :field_name

    JOINER = "/"

    # Create a new FieldRef
    #
    # @param doc_ref [String] Document reference
    # @param field_name [String] Field name
    # @param string_value [String] Optional pre-computed string representation
    def initialize(doc_ref, field_name, string_value = nil)
      @doc_ref = doc_ref
      @field_name = field_name
      @string_value = string_value
    end

    # Parse FieldRef from string
    #
    # @param str [String] String in format "fieldName/docRef"
    # @return [FieldRef] Parsed field reference
    # @raise [RuntimeError] If string doesn't contain joiner
    def self.from_string(str)
      n = str.index(JOINER)

      raise "malformed field ref string" if n.nil?

      field_name = str[0...n]
      doc_ref = str[(n + 1)..-1]

      new(doc_ref, field_name, str)
    end

    # Convert to string representation
    #
    # @return [String] String in format "fieldName/docRef"
    def to_s
      @string_value ||= "#{@field_name}#{JOINER}#{@doc_ref}"
    end
  end
end
