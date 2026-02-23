module LunrQuery
  # Sparse vector for TF-IDF scoring
  #
  # Stores elements as a flat array: [idx, val, idx, val, ...]
  # Indices are kept in sorted order for efficient binary search
  # and dot product calculation.
  class Vector
    attr_reader :elements

    # Creates a new Vector
    #
    # @param elements [Array] Optional array of elements in flat format
    def initialize(elements = nil)
      @elements = elements || []
      @magnitude_cache = 0
    end

    # Calculate position to insert element at given index using binary search
    #
    # @param index [Integer] The index to find position for
    # @return [Integer] Position in elements array (even number)
    def position_for_index(index)
      return 0 if @elements.length == 0

      start_pos = 0
      end_pos = @elements.length / 2
      slice_length = end_pos - start_pos
      pivot_point = (slice_length / 2).floor
      pivot_index = @elements[pivot_point * 2]

      while slice_length > 1
        if pivot_index < index
          start_pos = pivot_point
        end

        if pivot_index > index
          end_pos = pivot_point
        end

        break if pivot_index == index

        slice_length = end_pos - start_pos
        pivot_point = start_pos + (slice_length / 2).floor
        pivot_index = @elements[pivot_point * 2]
      end

      return pivot_point * 2 if pivot_index == index
      return pivot_point * 2 if pivot_index > index
      return (pivot_point + 1) * 2 if pivot_index < index
    end

    # Insert element at index
    #
    # Raises error if index already exists
    #
    # @param insert_idx [Integer] Index to insert at
    # @param val [Numeric] Value to insert
    def insert(insert_idx, val)
      upsert(insert_idx, val) { raise "duplicate index" }
    end

    # Insert or update element at index
    #
    # @param insert_idx [Integer] Index to insert at
    # @param val [Numeric] Value to insert
    # @param fn [Proc] Optional function called on update (receives current, new value)
    def upsert(insert_idx, val, &fn)
      @magnitude_cache = 0
      position = position_for_index(insert_idx)

      if @elements[position] == insert_idx
        # Update existing value
        merge_fn = fn || ->(current, passed) { passed }
        @elements[position + 1] = merge_fn.call(@elements[position + 1], val)
      else
        # Insert new value
        @elements.insert(position, insert_idx, val)
      end
    end

    # Calculate magnitude of vector (cached)
    #
    # @return [Float] Vector magnitude
    def magnitude
      return @magnitude_cache if @magnitude_cache != 0

      sum_of_squares = 0
      i = 1
      while i < @elements.length
        val = @elements[i]
        sum_of_squares += val * val
        i += 2
      end

      @magnitude_cache = Math.sqrt(sum_of_squares)
    end

    # Calculate dot product with another vector
    #
    # @param other_vector [Vector] Vector to dot with
    # @return [Numeric] Dot product
    def dot(other_vector)
      dot_product = 0
      a = @elements
      b = other_vector.elements
      a_len = a.length
      b_len = b.length

      i = 0
      j = 0

      while i < a_len && j < b_len
        a_val = a[i]
        b_val = b[j]

        if a_val < b_val
          i += 2
        elsif a_val > b_val
          j += 2
        else # a_val == b_val
          dot_product += a[i + 1] * b[j + 1]
          i += 2
          j += 2
        end
      end

      dot_product
    end

    # Calculate cosine similarity with another vector
    #
    # @param other_vector [Vector] Vector to compare with
    # @return [Float] Similarity score (0-1)
    def similarity(other_vector)
      mag = magnitude
      return 0 if mag == 0

      dot(other_vector) / mag
    end

    # Convert to array of values (without indices)
    #
    # @return [Array] Array of values
    def to_array
      output = []
      i = 1
      while i < @elements.length
        output << @elements[i]
        i += 2
      end
      output
    end

    # Serialize to JSON-compatible format
    #
    # @return [Array] Elements array
    def to_json
      @elements
    end
  end
end
