module LunrQuery
  # Query builder and clause container
  #
  # Provides programmatic query construction with clauses.
  # Each clause specifies term, fields, boost, presence, wildcards.
  class Query
    attr_reader :clauses, :all_fields

    # Wildcard constants (bitwise flags)
    WILDCARD_NONE = 0
    WILDCARD_LEADING = 1
    WILDCARD_TRAILING = 2

    # Presence constants
    PRESENCE_OPTIONAL = 1
    PRESENCE_REQUIRED = 2
    PRESENCE_PROHIBITED = 3

    # Create new Query
    #
    # @param all_fields [Array<String>] Available index fields
    def initialize(all_fields)
      @clauses = []
      @all_fields = all_fields
    end

    # Add clause to query with defaults
    #
    # @param clause [Hash] Clause hash with :term and optional settings
    # @return [Query] Self for chaining
    def clause(clause)
      # Set defaults
      clause[:fields] ||= @all_fields
      clause[:boost] ||= 1
      clause[:use_pipeline] = true unless clause.key?(:use_pipeline)
      clause[:wildcard] ||= WILDCARD_NONE
      clause[:presence] ||= PRESENCE_OPTIONAL

      # Apply wildcard modifiers to term
      term = clause[:term]
      wildcard = clause[:wildcard]

      # Add leading wildcard if requested and not already present
      if (wildcard & WILDCARD_LEADING) != 0 && term[0] != '*'
        term = "*#{term}"
      end

      # Add trailing wildcard if requested and not already present
      if (wildcard & WILDCARD_TRAILING) != 0 && term[-1] != '*'
        term = "#{term}*"
      end

      clause[:term] = term

      @clauses << clause
      self
    end

    # Add term(s) to query
    #
    # Convenience method that creates clauses.
    #
    # @param term [String, Array<String>] Term or array of terms
    # @param options [Hash] Optional clause settings
    # @return [Query] Self for chaining
    def term(term, options = nil)
      if term.is_a?(Array)
        term.each do |t|
          # Clone options for each term to prevent mutation
          opts = options ? options.dup : {}
          self.term(t, opts)
        end
        return self
      end

      clause_hash = options ? options.dup : {}
      clause_hash[:term] = term.to_s

      clause(clause_hash)
      self
    end

    # Check if query is negated
    #
    # A negated query has all clauses with PROHIBITED presence.
    #
    # @return [Boolean] True if all clauses are prohibited
    def is_negated?
      return false if @clauses.empty?

      @clauses.all? { |c| c[:presence] == PRESENCE_PROHIBITED }
    end
  end
end
