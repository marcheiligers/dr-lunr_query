module LunrQuery
  # Query string lexer
  #
  # Tokenizes query strings into lexemes for parsing.
  # Uses character-by-character state machine (no regex).
  class QueryLexer
    # Lexeme types
    EOS = 'EOS'
    FIELD = 'FIELD'
    TERM = 'TERM'
    EDIT_DISTANCE = 'EDIT_DISTANCE'
    BOOST = 'BOOST'
    PRESENCE = 'PRESENCE'

    attr_reader :lexemes, :str

    # Create new QueryLexer
    #
    # @param str [String] Query string to lex
    def initialize(str)
      @str = str
      @length = str.length
      @pos = 0
      @start = 0
      @lexemes = []
      @escape_char_positions = []
    end

    # Run the lexer
    def run
      state = :lex_text

      while state
        state = send(state)
      end
    end

    # Get current character and advance position
    #
    # @return [String, nil] Current character or nil if EOS
    def next_char
      return nil if @pos >= @length

      char = @str[@pos]
      @pos += 1
      char
    end

    # Move position back one character
    def backup
      @pos -= 1
    end

    # Get current token width
    #
    # @return [Integer] Characters between start and pos
    def width
      @pos - @start
    end

    # Ignore current token (reset start to pos)
    def ignore
      @start = @pos
    end

    # Emit lexeme of given type
    #
    # @param type [String] Lexeme type constant
    def emit(type)
      lexeme = {
        type: type,
        str: slice_string,
        start: @start,
        end: @pos
      }
      @lexemes << lexeme
      @start = @pos
    end

    # Get string slice from start to pos
    #
    # @return [String] Sliced and unescaped string
    def slice_string
      str = @str[@start...@pos]

      # Remove escape characters
      @escape_char_positions.each do |pos|
        if pos >= @start && pos < @pos
          # Calculate position in substring
          idx = pos - @start
          str = str[0...idx] + str[(idx + 1)..-1] if idx < str.length
        end
      end

      str
    end

    # Record escape character position
    def escape_character
      @escape_char_positions << (@pos - 1)
    end

    # Accept run of digits
    def accept_digit_run
      while true
        char = next_char
        break if char.nil?

        if char >= '0' && char <= '9'
          next
        else
          backup
          break
        end
      end
    end

    # Check if more input available
    #
    # @return [Boolean] True if pos < length
    def more?
      @pos < @length
    end

    private

    # Main lexing state
    def lex_text
      loop do
        char = next_char

        # End of string
        return :lex_eos if char.nil?

        # Escape character (backslash)
        if char == '\\'
          escape_character
          # Skip the escaped character
          next_char
          next
        end

        # Field separator
        if char == ':'
          return :lex_field
        end

        # Edit distance
        if char == '~'
          backup
          emit(TERM) if width > 0
          return :lex_edit_distance
        end

        # Boost
        if char == '^'
          backup
          emit(TERM) if width > 0
          return :lex_boost
        end

        # Presence: + (required)
        if char == '+' && width == 1
          emit(PRESENCE)
          return :lex_text
        end

        # Presence: - (prohibited)
        if char == '-' && width == 1
          emit(PRESENCE)
          return :lex_text
        end

        # Term separator (whitespace and hyphen)
        if char == ' ' || char == "\t" || char == "\n" || char == "\r" || char == '-'
          return :lex_term
        end
      end
    end

    # Lex field name
    def lex_field
      # Backup to before ':'
      backup
      emit(FIELD)

      # Skip ':'
      next_char
      ignore

      :lex_text
    end

    # Lex term
    def lex_term
      # Backup to before separator
      backup

      # Emit term if we have content
      emit(TERM) if width > 0

      # Skip separator(s)
      next_char
      ignore

      return :lex_text if more?
      :lex_eos
    end

    # Lex edit distance (~N)
    def lex_edit_distance
      # Skip '~'
      next_char
      ignore

      # Accept digits
      accept_digit_run

      emit(EDIT_DISTANCE)
      :lex_text
    end

    # Lex boost (^N)
    def lex_boost
      # Skip '^'
      next_char
      ignore

      # Accept digits
      accept_digit_run

      emit(BOOST)
      :lex_text
    end

    # End of string
    def lex_eos
      # Emit final term if any
      emit(TERM) if width > 0

      # Emit EOS marker
      emit(EOS)

      nil # Stop state machine
    end
  end
end
