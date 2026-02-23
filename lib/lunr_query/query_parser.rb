module LunrQuery
  # Query string parser
  #
  # Parses query strings into Query objects using QueryLexer.
  # Implements state machine pattern for parsing.
  class QueryParser
    attr_reader :query, :lexer, :lexemes, :current_clause, :lexeme_idx

    # Create new QueryParser
    #
    # @param str [String] Query string to parse
    # @param query [Query] Query object to populate
    def initialize(str, query)
      @lexer = QueryLexer.new(str)
      @query = query
      @current_clause = {}
      @lexeme_idx = 0
    end

    # Parse query string
    #
    # @return [Query] Populated query object
    def parse
      @lexer.run
      @lexemes = @lexer.lexemes

      state = :parse_clause

      while state
        state = send(state)
      end

      @query
    end

    # Peek at current lexeme without consuming
    #
    # @return [Hash, nil] Current lexeme or nil
    def peek_lexeme
      @lexemes[@lexeme_idx]
    end

    # Consume current lexeme and advance
    #
    # @return [Hash, nil] Consumed lexeme or nil
    def consume_lexeme
      lexeme = peek_lexeme
      @lexeme_idx += 1
      lexeme
    end

    # Finish current clause and start new one
    def next_clause
      completed_clause = @current_clause
      @query.clause(completed_clause)
      @current_clause = {}
    end

    private

    # Parse clause entry point
    def parse_clause
      lexeme = peek_lexeme

      return nil if lexeme.nil?

      case lexeme[:type]
      when QueryLexer::PRESENCE
        :parse_presence
      when QueryLexer::FIELD
        :parse_field
      when QueryLexer::TERM
        :parse_term
      else
        error_message = "expected either a field or a term, found #{lexeme[:type]}"
        error_message += " with value '#{lexeme[:str]}'" if lexeme[:str] && lexeme[:str].length >= 1
        raise error_message
      end
    end

    # Parse presence modifier (+/-)
    def parse_presence
      lexeme = consume_lexeme

      return nil if lexeme.nil?

      case lexeme[:str]
      when '-'
        @current_clause[:presence] = Query::PRESENCE_PROHIBITED
      when '+'
        @current_clause[:presence] = Query::PRESENCE_REQUIRED
      else
        raise "unrecognised presence operator '#{lexeme[:str]}'"
      end

      next_lexeme = peek_lexeme

      if next_lexeme.nil?
        raise "expecting term or field, found nothing"
      end

      case next_lexeme[:type]
      when QueryLexer::FIELD
        :parse_field
      when QueryLexer::TERM
        :parse_term
      else
        raise "expecting term or field, found '#{next_lexeme[:type]}'"
      end
    end

    # Parse field name
    def parse_field
      lexeme = consume_lexeme

      return nil if lexeme.nil?

      unless @query.all_fields.include?(lexeme[:str])
        possible_fields = @query.all_fields.map { |f| "'#{f}'" }.join(', ')
        raise "unrecognised field '#{lexeme[:str]}', possible fields: #{possible_fields}"
      end

      @current_clause[:fields] = [lexeme[:str]]

      next_lexeme = peek_lexeme

      if next_lexeme.nil?
        raise "expecting term, found nothing"
      end

      case next_lexeme[:type]
      when QueryLexer::TERM
        :parse_term
      else
        raise "expecting term, found '#{next_lexeme[:type]}'"
      end
    end

    # Parse term
    def parse_term
      lexeme = consume_lexeme

      return nil if lexeme.nil?

      # Convert to lowercase
      @current_clause[:term] = lexeme[:str].downcase

      # Disable pipeline for wildcard terms
      if lexeme[:str].include?('*')
        @current_clause[:use_pipeline] = false
      end

      next_lexeme = peek_lexeme

      if next_lexeme.nil?
        next_clause
        return nil
      end

      case next_lexeme[:type]
      when QueryLexer::TERM
        next_clause
        :parse_term
      when QueryLexer::FIELD
        next_clause
        :parse_field
      when QueryLexer::EDIT_DISTANCE
        :parse_edit_distance
      when QueryLexer::BOOST
        :parse_boost
      when QueryLexer::PRESENCE
        next_clause
        :parse_presence
      when QueryLexer::EOS
        next_clause
        nil
      else
        raise "Unexpected lexeme type '#{next_lexeme[:type]}'"
      end
    end

    # Parse edit distance (~N)
    def parse_edit_distance
      lexeme = consume_lexeme

      return nil if lexeme.nil?

      edit_distance = lexeme[:str].to_i

      if edit_distance == 0 && lexeme[:str] != '0'
        raise "edit distance must be numeric"
      end

      @current_clause[:edit_distance] = edit_distance

      next_lexeme = peek_lexeme

      if next_lexeme.nil?
        next_clause
        return nil
      end

      case next_lexeme[:type]
      when QueryLexer::TERM
        next_clause
        :parse_term
      when QueryLexer::FIELD
        next_clause
        :parse_field
      when QueryLexer::BOOST
        :parse_boost
      when QueryLexer::PRESENCE
        next_clause
        :parse_presence
      when QueryLexer::EOS
        next_clause
        nil
      else
        raise "Unexpected lexeme type '#{next_lexeme[:type]}'"
      end
    end

    # Parse boost (^N)
    def parse_boost
      lexeme = consume_lexeme

      return nil if lexeme.nil?

      boost = lexeme[:str].to_i

      if boost == 0 && lexeme[:str] != '0'
        raise "boost must be numeric"
      end

      @current_clause[:boost] = boost

      next_lexeme = peek_lexeme

      if next_lexeme.nil?
        next_clause
        return nil
      end

      case next_lexeme[:type]
      when QueryLexer::TERM
        next_clause
        :parse_term
      when QueryLexer::FIELD
        next_clause
        :parse_field
      when QueryLexer::PRESENCE
        next_clause
        :parse_presence
      when QueryLexer::EOS
        next_clause
        nil
      else
        raise "Unexpected lexeme type '#{next_lexeme[:type]}'"
      end
    end
  end
end
