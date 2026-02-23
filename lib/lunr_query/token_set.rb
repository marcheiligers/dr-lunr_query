module LunrQuery
  # Minimal finite state automaton for term matching
  #
  # Supports single wildcard (*) per term via start_with?/end_with? matching.
  # Supports fuzzy matching via Damerau-Levenshtein distance.
  class TokenSet
    attr_accessor :final, :edges
    attr_reader :id, :wildcard_pattern, :fuzzy_term, :fuzzy_distance

    @@next_id = 1

    # Create new TokenSet node
    def initialize
      @final = false
      @edges = {}
      @id = @@next_id
      @wildcard_pattern = nil
      @fuzzy_term = nil
      @fuzzy_distance = nil
      @@next_id += 1
    end

    # Build TokenSet from string
    #
    # @param str [String] String to build from (may contain single '*' wildcard)
    # @return [TokenSet] Root node of FSM
    def self.from_string(str)
      if str.include?('*')
        wildcard_count = str.count('*')
        if wildcard_count > 1
          raise "Only one wildcard (*) per term is supported, found #{wildcard_count} in '#{str}'"
        end

        node = new
        node.instance_variable_set(:@wildcard_pattern, str)
        return node
      end

      root = new
      current = root

      str.each_char do |char|
        new_node = new
        current.edges[char] = new_node
        current = new_node
      end

      current.final = true
      root
    end

    # Build TokenSet from sorted array of strings
    #
    # @param arr [Array<String>] Sorted array of strings
    # @return [TokenSet] Root node
    def self.from_array(arr)
      # Check if sorted
      unless arr == arr.sort
        raise "TokenSet.from_array requires a sorted array"
      end

      builder = Builder.new
      arr.each { |str| builder.insert(str) }
      builder.finish
      builder.root
    end

    # Build TokenSet for fuzzy matching
    #
    # @param str [String] Term to fuzzy match
    # @param edit_distance [Integer] Maximum edit distance
    # @return [TokenSet] Node storing fuzzy parameters
    def self.from_fuzzy_string(str, edit_distance)
      node = new
      node.instance_variable_set(:@fuzzy_term, str)
      node.instance_variable_set(:@fuzzy_distance, edit_distance)
      node
    end

    # Damerau-Levenshtein distance between two strings
    #
    # Supports substitution, insertion, deletion, and transposition.
    #
    # @param s1 [String] First string
    # @param s2 [String] Second string
    # @return [Integer] Edit distance
    def self.levenshtein_distance(s1, s2)
      m = s1.length
      n = s2.length

      d = Array.new(m + 1) { Array.new(n + 1, 0) }

      (0..m).each { |i| d[i][0] = i }
      (0..n).each { |j| d[0][j] = j }

      (1..m).each do |i|
        (1..n).each do |j|
          cost = s1[i - 1] == s2[j - 1] ? 0 : 1

          d[i][j] = [
            d[i - 1][j] + 1,       # deletion
            d[i][j - 1] + 1,       # insertion
            d[i - 1][j - 1] + cost  # substitution
          ].min

          # transposition
          if i > 1 && j > 1 && s1[i - 1] == s2[j - 2] && s1[i - 2] == s2[j - 1]
            d[i][j] = [d[i][j], d[i - 2][j - 2] + 1].min
          end
        end
      end

      d[m][n]
    end

    # Build from query clause
    #
    # @param clause [Hash] Query clause
    # @return [TokenSet] Root node
    def self.from_clause(clause)
      if clause[:edit_distance]
        from_fuzzy_string(clause[:term], clause[:edit_distance])
      else
        from_string(clause[:term])
      end
    end

    # Convert TokenSet to array of strings
    #
    # @return [Array<String>] All terms in the set
    def to_array
      words = []
      stack = [{ prefix: '', node: self }]

      while stack.length > 0
        frame = stack.pop

        words << frame[:prefix] if frame[:node].final

        frame[:node].edges.each do |char, node|
          stack << { prefix: frame[:prefix] + char, node: node }
        end
      end

      words
    end

    # Intersect with another TokenSet
    #
    # Returns terms that exist in both sets.
    # Supports wildcard patterns via start_with?/end_with? matching.
    #
    # @param other [TokenSet] TokenSet to intersect with
    # @return [TokenSet] New TokenSet with intersection
    def intersect(other)
      if other.wildcard_pattern
        return wildcard_intersect(other.wildcard_pattern)
      end

      if other.fuzzy_term
        return fuzzy_intersect(other.fuzzy_term, other.fuzzy_distance)
      end

      output = TokenSet.new
      stack = [{ q_node: other, output: output, node: self }]

      while stack.length > 0
        frame = stack.pop

        # Mark as final if both nodes are final
        if frame[:node].final && frame[:q_node].final
          frame[:output].final = true
        end

        # Find common edges
        frame[:node].edges.each do |char, node|
          next unless frame[:q_node].edges[char]

          q_node = frame[:q_node].edges[char]

          # Get or create output node for this edge
          unless frame[:output].edges[char]
            frame[:output].edges[char] = TokenSet.new
          end

          stack << {
            q_node: q_node,
            node: node,
            output: frame[:output].edges[char]
          }
        end
      end

      output
    end

    # String representation for identification
    #
    # @return [String] String representation
    def to_s
      # Simple representation: finality + edge count + edge chars
      final_marker = @final ? '1' : '0'
      edge_chars = @edges.keys.sort.join
      edge_ids = @edges.values.map(&:id).sort.join(',')

      "#{@id}#{final_marker}#{edge_chars}#{edge_ids}"
    end

    # Builder for constructing TokenSet from multiple strings
    class Builder
      attr_reader :root

      def initialize
        @previous_word = ""
        @root = TokenSet.new
        @unchecked_nodes = []
        @minimized_nodes = {}
      end

      # Insert a word into the builder
      #
      # @param word [String] Word to insert (must be >= previous word)
      def insert(word)
        if word < @previous_word
          raise "Out of order word insertion"
        end

        # Find common prefix
        common_prefix = 0
        (0...[word.length, @previous_word.length].min).each do |i|
          break if word[i] != @previous_word[i]
          common_prefix += 1
        end

        # Minimize nodes from previous word suffix
        minimize(common_prefix)

        # Add new nodes for word suffix
        node = if @unchecked_nodes.empty?
          @root
        else
          @unchecked_nodes.last[:child]
        end

        (common_prefix...word.length).each do |i|
          new_node = TokenSet.new
          char = word[i]

          node.edges[char] = new_node
          @unchecked_nodes << { parent: node, char: char, child: new_node }

          node = new_node
        end

        node.final = true
        @previous_word = word
      end

      # Finish building and minimize remaining nodes
      def finish
        minimize(0)
      end

      private

      # Minimize nodes
      #
      # @param down_to [Integer] How many nodes to keep
      def minimize(down_to)
        while @unchecked_nodes.length > down_to
          node_data = @unchecked_nodes.pop
          child_key = node_data[:child].to_s

          if @minimized_nodes[child_key]
            # Replace with existing minimized node
            node_data[:parent].edges[node_data[:char]] = @minimized_nodes[child_key]
          else
            # Add to minimized nodes
            @minimized_nodes[child_key] = node_data[:child]
          end
        end
      end
    end

    private

    # Intersect using wildcard string matching
    #
    # @param pattern [String] Wildcard pattern (e.g. 'foo*', '*bar', 'f*r')
    # @return [TokenSet] New TokenSet with matching terms
    def wildcard_intersect(pattern)
      all_terms = to_array
      parts = pattern.split('*', 2)
      prefix = parts[0]
      suffix = parts[1]

      matching = all_terms.select do |term|
        (prefix.empty? || term.start_with?(prefix)) &&
        (suffix.empty? || term.end_with?(suffix)) &&
        term.length >= prefix.length + suffix.length
      end

      return TokenSet.new if matching.empty?
      TokenSet.from_array(matching.sort)
    end

    # Intersect using Damerau-Levenshtein distance
    #
    # @param term [String] Term to fuzzy match
    # @param max_distance [Integer] Maximum edit distance
    # @return [TokenSet] New TokenSet with matching terms
    def fuzzy_intersect(term, max_distance)
      all_terms = to_array

      matching = all_terms.select do |t|
        self.class.levenshtein_distance(term, t) <= max_distance
      end

      return TokenSet.new if matching.empty?
      TokenSet.from_array(matching.sort)
    end
  end
end
