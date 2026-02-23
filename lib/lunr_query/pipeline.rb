module LunrQuery
  # Token processing pipeline
  #
  # Chains processing functions (stemmer, stop words, etc.)
  class Pipeline
    attr_reader :functions

    # Registered pipeline functions
    @@registered_functions = {}

    # Register a pipeline function
    #
    # @param name [String] Function name
    # @param fn [Proc] Function to register
    def self.register_function(name, fn)
      @@registered_functions[name] = fn
    end

    # Get registered function by name
    #
    # @param name [String] Function name
    # @return [Proc, nil] Function or nil
    def self.get_function(name)
      @@registered_functions[name]
    end

    # Create new Pipeline
    def initialize
      @functions = []
    end

    # Add function(s) to pipeline
    #
    # @param fns [Array<Proc, String>] Functions or function names
    def add(*fns)
      fns.each do |fn|
        if fn.is_a?(String)
          # Look up registered function
          registered = self.class.get_function(fn)
          @functions << registered if registered
        else
          @functions << fn
        end
      end
    end

    # Run string through pipeline
    #
    # @param str [String] String to process
    # @return [Array<String>] Processed tokens
    def run_string(str)
      # TODO: Implement tokenization
      # TODO: Run through pipeline functions
      # TODO: Filter out nil/empty results

      # For now, just return the string as a single token
      # This is a no-op pipeline
      tokens = [str]

      # Run through each function
      @functions.each do |fn|
        new_tokens = []
        tokens.each do |token|
          result = fn.call(token)
          if result.is_a?(Array)
            new_tokens.concat(result)
          elsif result
            new_tokens << result
          end
        end
        tokens = new_tokens
      end

      tokens
    end

    # Serialize pipeline to array of function names
    #
    # @return [Array<String>] Function names
    def to_json
      # Return list of function names
      # For now, empty since we have no registered functions
      []
    end

    # Load pipeline from serialized data
    #
    # @param data [Array<String>] Function names
    # @return [Pipeline] New pipeline
    def self.load(data)
      pipeline = new

      data.each do |fn_name|
        pipeline.add(fn_name)
      end

      pipeline
    end
  end

  # Common English stopwords
  # These are filtered out during indexing and search
  STOPWORDS = {
    'a' => true,
    'able' => true,
    'about' => true,
    'across' => true,
    'after' => true,
    'all' => true,
    'almost' => true,
    'also' => true,
    'am' => true,
    'among' => true,
    'an' => true,
    'and' => true,
    'any' => true,
    'are' => true,
    'as' => true,
    'at' => true,
    'be' => true,
    'because' => true,
    'been' => true,
    'but' => true,
    'by' => true,
    'can' => true,
    'cannot' => true,
    'could' => true,
    'dear' => true,
    'did' => true,
    'do' => true,
    'does' => true,
    'either' => true,
    'else' => true,
    'ever' => true,
    'every' => true,
    'for' => true,
    'from' => true,
    'get' => true,
    'got' => true,
    'had' => true,
    'has' => true,
    'have' => true,
    'he' => true,
    'her' => true,
    'hers' => true,
    'him' => true,
    'his' => true,
    'how' => true,
    'however' => true,
    'i' => true,
    'if' => true,
    'in' => true,
    'into' => true,
    'is' => true,
    'it' => true,
    'its' => true,
    'just' => true,
    'least' => true,
    'let' => true,
    'like' => true,
    'likely' => true,
    'may' => true,
    'me' => true,
    'might' => true,
    'most' => true,
    'must' => true,
    'my' => true,
    'neither' => true,
    'no' => true,
    'nor' => true,
    'not' => true,
    'of' => true,
    'off' => true,
    'often' => true,
    'on' => true,
    'only' => true,
    'or' => true,
    'other' => true,
    'our' => true,
    'own' => true,
    'rather' => true,
    'said' => true,
    'say' => true,
    'says' => true,
    'she' => true,
    'should' => true,
    'since' => true,
    'so' => true,
    'some' => true,
    'than' => true,
    'that' => true,
    'the' => true,
    'their' => true,
    'them' => true,
    'then' => true,
    'there' => true,
    'these' => true,
    'they' => true,
    'this' => true,
    'tis' => true,
    'to' => true,
    'too' => true,
    'twas' => true,
    'us' => true,
    'wants' => true,
    'was' => true,
    'we' => true,
    'were' => true,
    'what' => true,
    'when' => true,
    'where' => true,
    'which' => true,
    'while' => true,
    'who' => true,
    'whom' => true,
    'why' => true,
    'will' => true,
    'with' => true,
    'would' => true,
    'yet' => true,
    'you' => true,
    'your' => true
  }

  # Stop word filter function
  # Filters out common English words that don't add semantic value
  #
  # @param token [String] Token to check
  # @return [String, nil] Token if not a stopword, nil if filtered
  STOP_WORD_FILTER = ->(token) {
    # Case-insensitive lookup
    if STOPWORDS[token.downcase]
      nil  # Filter out stopword
    else
      token  # Pass through non-stopword
    end
  }

  # Register the stopWordFilter function
  Pipeline.register_function('stopWordFilter', STOP_WORD_FILTER)
end
