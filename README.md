# LunrQuery

A DragonRuby (mRuby) library for querying pre-built Lunr.js search indexes.

## Overview

LunrQuery enables you to use Lunr.js indexes in your DragonRuby applications. Create and serialize indexes in JavaScript using Lunr.js, then load and query them in DragonRuby with full search capabilities including field scoping, presence modifiers, and scoring.

Based on Lunr.js v2.3.9.

## Installation

Copy the `lib/lunr_query` directory and `lib/lunr_query.rb` file into your DragonRuby project.

```
your_game/
├── app/
│   └── main.rb
└── lib/
    ├── lunr_query.rb
    └── lunr_query/
        ├── index.rb
        ├── query.rb
        └── ...
```

## Quick Start

```ruby
require 'lib/lunr_query.rb'

# Load serialized index (created with Lunr.js)
index_data = $gtk.parse_json_file('data/search_index.json')
index = LunrQuery::Index.load(index_data)

# Search
results = index.search('dragon')

# Display results
results.each do |result|
  puts "#{result[:ref]} (score: #{result[:score]})"
end
```

## Creating Indexes

Indexes must be created and serialized using Lunr.js in JavaScript/Node.js:

```javascript
const lunr = require('lunr');
const fs = require('fs');

// Create index
const idx = lunr(function() {
  this.ref('id');
  this.field('title');
  this.field('body');

  documents.forEach(doc => this.add(doc));
});

// Serialize to JSON
const serialized = JSON.stringify(idx);
fs.writeFileSync('search_index.json', serialized);
```

Then load the JSON file in DragonRuby:

```ruby
index_data = $gtk.parse_json_file('data/search_index.json')
index = LunrQuery::Index.load(index_data)
```

## Query Syntax

LunrQuery supports the full Lunr.js query syntax:

### Basic Search

```ruby
# Search for a term across all fields
results = index.search('dragon')
```

### Field-Specific Search

```ruby
# Search only in title field
results = index.search('title:dragon')

# Search in multiple fields
results = index.search('title:dragon body:ruby')
```

### Presence Modifiers

```ruby
# Required: document must contain term
results = index.search('+dragon')

# Prohibited: document must not contain term
results = index.search('-dragon')

# Combined
results = index.search('+game -mobile')
```

### Boosts

```ruby
# Boost term importance (default is 1)
results = index.search('dragon^10')

# Different boosts for different terms
results = index.search('dragon^10 ruby^5')
```

### Wildcards

```ruby
# Trailing wildcard - matches terms starting with 'drag'
results = index.search('drag*')

# Leading wildcard - matches terms ending with 'gon'
results = index.search('*gon')

# Contained wildcard - matches terms starting with 'dr' and ending with 'on'
results = index.search('dr*on')
```

One wildcard `*` per term is supported. When used with a stemmer pipeline, the non-wildcard portion is automatically stemmed before matching (e.g. `commande*` becomes `command*`).

### Fuzzy Matching

```ruby
# Match terms within edit distance 1 of 'dragon'
results = index.search('dragon~1')

# Edit distance 2 allows more variation
results = index.search('drgon~2')
```

Fuzzy matching uses Damerau-Levenshtein distance, supporting substitution, insertion, deletion, and transposition edits. When used with a stemmer pipeline, the term is stemmed before fuzzy matching.

### Multiple Terms

```ruby
# Documents matching any term
results = index.search('dragon ruby game')

# Required and optional terms
results = index.search('+game dragon ruby')
```

### Combined Queries

```ruby
# Field scoping with presence and boosts
results = index.search('title:dragon^10 +body:ruby -body:mobile')
```

## API Reference

### LunrQuery::Index

#### Index.load(data)

Load a serialized Lunr.js index.

**Parameters:**
- `data` (Hash): Parsed JSON data from Lunr.js serialization

**Returns:** LunrQuery::Index instance

```ruby
index_data = $gtk.parse_json_file('data/index.json')
index = LunrQuery::Index.load(index_data)
```

#### index.search(query_string)

Search the index with a query string.

**Parameters:**
- `query_string` (String): Query using Lunr.js syntax

**Returns:** Array of result hashes, sorted by score (descending)

```ruby
results = index.search('dragon ruby')
```

**Result Format:**
```ruby
[
  {
    ref: "doc1",              # Document reference
    score: 0.523,             # Relevance score (higher is better)
    match_data: {             # Metadata about matches
      metadata: {
        "search_term" => {    # Matched term (after stemming)
          "field_name" => {   # Field where term was found
            "position" => [   # Character positions (if enabled)
              [start, length] # [character offset, word length]
            ]
          }
        }
      }
    }
  }
]
```

**Position Metadata:**

To include character position information in results, configure the Lunr.js index builder with `metadataWhitelist`:

```javascript
const idx = lunr(function() {
  this.metadataWhitelist = ['position'];
  // ... rest of configuration
});
```

This adds position data to match_data showing where each term appears in the original text:
- `start`: Character offset where the word begins
- `length`: Number of characters in the matched word

Example: Searching for "dizzy" might match the stemmed term "dizzi" from the word "dizziness" at position `[1224, 9]`.

#### index.fields

Returns array of searchable field names.

```ruby
index.fields  # => ['title', 'body', 'tags']
```

#### index.pipeline

Returns the Pipeline instance used for token processing.

```ruby
index.pipeline.functions  # => [#<Proc>, ...]
```

### LunrQuery::Pipeline

#### Pipeline.register_function(name, fn)

Register a custom pipeline function.

**Parameters:**
- `name` (String): Function name
- `fn` (Proc): Function that takes a token and returns token, array of tokens, or nil

```ruby
LunrQuery::Pipeline.register_function('upcase', ->(token) { token.upcase })
```

#### Built-in Pipeline Functions

**stopWordFilter**: Filters common English stopwords

```ruby
pipeline = LunrQuery::Pipeline.new
pipeline.add('stopWordFilter')
result = pipeline.run_string('the')  # => []
result = pipeline.run_string('dragon')  # => ['dragon']
```

## Example Usage

### Game Documentation Search

```ruby
require 'lib/lunr_query.rb'

def boot(args)
  return if args.state.index

  # Load pre-built index
  index_data = $gtk.parse_json_file('data/docs_index.json')
  args.state.index = LunrQuery::Index.load(index_data)
  args.state.search_results = []
end

def tick(args)
  # Get user input
  if args.inputs.keyboard.key_down.enter && args.state.search_query
    # Perform search
    args.state.search_results = args.state.index.search(args.state.search_query)
  end

  # Display results
  args.state.search_results.each_with_index do |result, i|
    y = 600 - (i * 30)
    args.outputs.labels << [100, y, "#{result[:ref]} (#{result[:score].round(3)})"]
  end
end
```

### Document Browser

```ruby
# Index contains game entities
index_data = $gtk.parse_json_file('data/entities_index.json')
index = LunrQuery::Index.load(index_data)

# Search for enemies
enemy_results = index.search('type:enemy +aggressive')

# Get references to load entity data
enemy_refs = enemy_results.map { |r| r[:ref] }

# Load entity data
enemies = enemy_refs.map { |ref| load_entity(ref) }
```

## Limitations

- **Single wildcard per term**: Only one `*` per search term is supported. Multiple wildcards (e.g. `*drag*`) will raise an error.
- **No RegExp**: DragonRuby/mRuby lacks RegExp support. Wildcard and fuzzy matching use string operations (`start_with?`/`end_with?` and Damerau-Levenshtein distance) instead.

## License

MIT License - see LICENSE file for details.

## Credits

* Based on [Lunr.js](https://lunrjs.com/) by Oliver Nightingale.
* Porter Stemmer translated from original C version written by [Martin Porter](https://tartarus.org/martin/PorterStemmer/)

### Astronaut biographies from Wikipedia:
* [Neil Armstrong](https://en.wikipedia.org/wiki/Neil_Armstrong)
* [Buzz Aldrin](https://en.wikipedia.org/wiki/Buzz_Aldrin)
* [Michael Collins](https://en.wikipedia.org/wiki/Michael_Collins_(astronaut))
* [Jim Lovell](https://en.wikipedia.org/wiki/Jim_Lovell)
* [Alan Shepard](https://en.wikipedia.org/wiki/Alan_Shepard)
