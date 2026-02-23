module LunrQuery
  # UTF-8 aware string operations for mRuby without MRB_UTF8_STRING
  #
  # mRuby's String#slice and String#length operate on bytes, not characters.
  # These helpers use String#bytes to correctly handle multi-byte UTF-8.
  module UTF8
    extend self

    # Returns the number of UTF-8 characters in a string.
    def length(str)
      count = 0
      str.bytes.each do |byte|
        # Count only lead bytes (not continuation bytes 10xxxxxx)
        count += 1 unless (byte & 0xC0) == 0x80
      end
      count
    end

    # Slices a string by character position, not byte position.
    #
    # @param str [String] UTF-8 encoded string
    # @param char_start [Integer] Starting character index
    # @param char_length [Integer] Number of characters to extract
    # @return [String] The extracted substring
    def slice(str, char_start, char_length)
      b = str.bytes
      total = b.length

      # Find byte offset of char_start
      byte_pos = 0
      char_count = 0
      while byte_pos < total && char_count < char_start
        byte = b[byte_pos]
        if byte < 0x80
          byte_pos += 1
        elsif byte < 0xE0
          byte_pos += 2
        elsif byte < 0xF0
          byte_pos += 3
        else
          byte_pos += 4
        end
        char_count += 1
      end

      byte_start = byte_pos

      # Count char_length characters
      chars_counted = 0
      while byte_pos < total && chars_counted < char_length
        byte = b[byte_pos]
        if byte < 0x80
          byte_pos += 1
        elsif byte < 0xE0
          byte_pos += 2
        elsif byte < 0xF0
          byte_pos += 3
        else
          byte_pos += 4
        end
        chars_counted += 1
      end

      str[byte_start, byte_pos - byte_start] || ''
    end
  end
end
