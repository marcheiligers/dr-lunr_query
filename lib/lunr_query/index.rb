module LunrQuery
  # Main search index interface
  #
  # Loads pre-built Lunr.js indexes and performs searches.
  class Index
    attr_reader :inverted_index, :field_vectors, :token_set, :fields, :pipeline

    # Load index from serialized hash
    #
    # @param data [Hash] Serialized index data from Lunr.js
    # @return [Index] Loaded index
    def self.load(data)
      index = new

      # Load fields
      index.instance_variable_set(:@fields, data['fields'] || [])

      # Load pipeline
      pipeline_data = data['pipeline'] || []
      index.instance_variable_set(:@pipeline, Pipeline.load(pipeline_data))

      # Load field vectors
      field_vectors = {}
      (data['fieldVectors'] || []).each do |field_ref_str, elements|
        field_vectors[field_ref_str] = Vector.new(elements)
      end
      index.instance_variable_set(:@field_vectors, field_vectors)

      # Load inverted index
      inverted_index = {}
      (data['invertedIndex'] || []).each do |term, posting|
        inverted_index[term] = posting
      end
      index.instance_variable_set(:@inverted_index, inverted_index)

      # Build token set from all terms
      all_terms = inverted_index.keys.sort
      if all_terms.length > 0
        token_set = TokenSet.from_array(all_terms)
      else
        token_set = TokenSet.new
      end
      index.instance_variable_set(:@token_set, token_set)

      index
    end

    # Search index with query string
    #
    # @param query_string [String] Query string to search
    # @return [Array<Hash>] Search results
    def search(query_string)
      query_obj = Query.new(@fields)
      parser = QueryParser.new(query_string, query_obj)
      parser.parse

      query(query_obj)
    end

    # Execute query against index
    #
    # @param query_obj [Query] Query object
    # @return [Array<Hash>] Search results
    def query(query_obj)
      # Track matching documents
      matching_fields = {}
      all_required_matches = {}
      all_prohibited_matches = {}
      prohibited_docs = {}

      # Query vectors for scoring
      query_vectors = {}
      @fields.each do |field|
        query_vectors[field] = Vector.new
      end

      # Process each clause
      query_obj.clauses.each do |clause|
        # Get clause fields (default to all fields)
        clause_fields = clause[:fields] || @fields

        # Process term through pipeline if needed
        terms = if clause[:use_pipeline] != false
          @pipeline.run_string(clause[:term])
        elsif @pipeline.functions.length > 0
          stem_wildcard_term(clause[:term])
        else
          [clause[:term]]
        end

        # For each processed term
        terms.each do |term|
          # Expand wildcard/fuzzy terms using TokenSet intersection
          if term.include?('*')
            term_token_set = TokenSet.from_string(term)
            expanded = @token_set.intersect(term_token_set).to_array
          elsif clause[:edit_distance]
            term_token_set = TokenSet.from_fuzzy_string(term, clause[:edit_distance])
            expanded = @token_set.intersect(term_token_set).to_array
          else
            expanded = [term]
          end

          expanded.each do |expanded_term|
            posting = @inverted_index[expanded_term]
            next unless posting

            term_index = posting['_index']
            boost = clause[:boost] || 1

            # For each field in this clause
            clause_fields.each do |field|
              field_posting = posting[field]
              next unless field_posting

              # Track matches per document
              field_posting.each do |doc_ref, metadata|
                # Track for presence filtering
                key = "#{field}/#{doc_ref}"

                case clause[:presence]
                when Query::PRESENCE_REQUIRED
                  all_required_matches[key] = true
                when Query::PRESENCE_PROHIBITED
                  all_prohibited_matches[key] = true
                  prohibited_docs[doc_ref] = true
                end

                # Track matching fields for scoring
                unless clause[:presence] == Query::PRESENCE_PROHIBITED
                  matching_fields[key] ||= {}
                  matching_fields[key][expanded_term] = metadata || {}
                end
              end

              # Add to query vector
              query_vectors[field].upsert(term_index, boost) { |a, b| a + b }
            end
          end
        end
      end

      # Score and collect results
      results = {}

      matching_fields.each do |field_ref, terms|
        # Get doc_ref first
        parts = field_ref.split('/')
        field = parts[0]
        doc_ref = parts[1..-1].join('/')

        # Check presence requirements - skip if doc is prohibited
        if prohibited_docs[doc_ref]
          next
        end

        if all_required_matches.length > 0 && !all_required_matches[field_ref]
          next
        end

        # Get field vector
        field_vector = @field_vectors[field_ref]
        next unless field_vector

        # Calculate score
        score = query_vectors[field].similarity(field_vector)
        next if score == 0

        # Accumulate score per document
        results[doc_ref] ||= { ref: doc_ref, score: 0, match_data: { metadata: {} } }
        results[doc_ref][:score] += score

        # Store matched terms per field in metadata with position info
        terms.each do |term, term_metadata|
          results[doc_ref][:match_data][:metadata][term] ||= {}
          results[doc_ref][:match_data][:metadata][term][field] = term_metadata
        end
      end

      # Sort by score descending
      results.values.sort_by { |r| -r[:score] }
    end

    private

    def initialize
      # Private constructor - use Index.load
    end

    # Stem a wildcard term, preserving wildcard position.
    # Strips '*', runs through pipeline, re-adds '*'.
    #
    # @param term [String] Term possibly containing '*'
    # @return [Array<String>] Stemmed term(s) with wildcard restored
    def stem_wildcard_term(term)
      unless term.include?('*')
        # Fuzzy or other non-wildcard term - just stem it
        stemmed = @pipeline.run_string(term)
        return stemmed.empty? ? [term] : stemmed
      end

      star_pos = term.index('*')

      if star_pos == 0
        # Leading: "*foo" -> stem("foo") -> "*stemmed"
        stemmed = @pipeline.run_string(term[1..-1])
        return [term] if stemmed.empty?
        stemmed.map { |s| "*#{s}" }
      elsif star_pos == term.length - 1
        # Trailing: "foo*" -> stem("foo") -> "stemmed*"
        stemmed = @pipeline.run_string(term[0..-2])
        return [term] if stemmed.empty?
        stemmed.map { |s| "#{s}*" }
      else
        # Contained: "fo*ar" -> stem each part
        parts = term.split('*', 2)
        stemmed_prefix = @pipeline.run_string(parts[0])
        stemmed_suffix = @pipeline.run_string(parts[1])
        p = stemmed_prefix.empty? ? parts[0] : stemmed_prefix[0]
        s = stemmed_suffix.empty? ? parts[1] : stemmed_suffix[0]
        ["#{p}*#{s}"]
      end
    end
  end
end
