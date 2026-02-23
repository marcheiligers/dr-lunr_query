module LunrQuery
  # Match metadata storage
  #
  # Stores metadata about term matches in the format:
  #   metadata[term][field][key] = array_of_values
  #
  # Example:
  #   metadata = {
  #     "green" => {
  #       "title" => { "position" => [1, 5] },
  #       "body" => { "position" => [10, 15, 20] }
  #     }
  #   }
  class MatchData
    attr_reader :metadata

    # Create new MatchData
    #
    # @param term [String] Optional term
    # @param field [String] Optional field name
    # @param metadata [Hash] Optional metadata hash
    def initialize(term = nil, field = nil, metadata = nil)
      @metadata = {}

      return if term.nil?

      # Clone metadata arrays to prevent mutation
      cloned_metadata = {}
      if metadata
        metadata.each do |key, value|
          cloned_metadata[key] = value.dup
        end
      end

      @metadata[term] = {}
      @metadata[term][field] = cloned_metadata
    end

    # Combine another MatchData into this one
    #
    # @param other_match_data [MatchData] MatchData to merge
    def combine(other_match_data)
      other_match_data.metadata.each do |term, fields|
        @metadata[term] ||= {}

        fields.each do |field, keys|
          @metadata[term][field] ||= {}

          keys.each do |key, value|
            if @metadata[term][field][key]
              # Concatenate arrays
              @metadata[term][field][key] = @metadata[term][field][key] + value
            else
              @metadata[term][field][key] = value
            end
          end
        end
      end
    end

    # Add metadata for a term/field pair
    #
    # @param term [String] Term
    # @param field [String] Field name
    # @param metadata [Hash] Metadata hash
    def add(term, field, metadata)
      unless @metadata.key?(term)
        @metadata[term] = {}
        @metadata[term][field] = metadata
        return
      end

      unless @metadata[term].key?(field)
        @metadata[term][field] = metadata
        return
      end

      # Merge metadata keys
      metadata.each do |key, value|
        if @metadata[term][field].key?(key)
          @metadata[term][field][key] = @metadata[term][field][key] + value
        else
          @metadata[term][field][key] = value
        end
      end
    end
  end
end
