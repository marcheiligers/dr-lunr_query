require 'lib/lunr_query.rb'

# Minimal test index fixture
def get_test_index_data
  {
    'version' => '2.3.9',
    'fields' => ['title', 'body'],
    'fieldVectors' => [
      ['title/a', [0, 0.5, 1, 0.3]],  # doc 'a': term 0 (green) weight 0.5, term 1 (plant) weight 0.3
      ['body/a', [0, 0.8]],             # doc 'a': term 0 (green) weight 0.8
      ['title/b', [1, 0.6]],            # doc 'b': term 1 (plant) weight 0.6
      ['body/b', [0, 0.4, 2, 0.5]]     # doc 'b': term 0 (green) weight 0.4, term 2 (study) weight 0.5
    ],
    'invertedIndex' => [
      ['green', {
        '_index' => 0,
        'title' => { 'a' => { 'position' => [1] } },
        'body' => { 'a' => { 'position' => [3] }, 'b' => { 'position' => [5] } }
      }],
      ['plant', {
        '_index' => 1,
        'title' => { 'a' => { 'position' => [2] }, 'b' => { 'position' => [1] } }
      }],
      ['study', {
        '_index' => 2,
        'body' => { 'b' => { 'position' => [8] } }
      }]
    ],
    'pipeline' => []
  }
end

def test_index_load(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  assert.equal! index.fields, ['title', 'body']
  assert.true! index.inverted_index.is_a?(Hash)
  assert.true! index.field_vectors.is_a?(Hash)
end

def test_index_search_single_term(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('green')

  # Should find docs 'a' and 'b' (both have 'green')
  assert.true! results.length > 0
  refs = results.map { |r| r[:ref] }
  assert.true! refs.include?('a') || refs.include?('b')
end

def test_index_search_scores(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('green')

  # Each result should have score
  results.each do |result|
    assert.true! result[:score] > 0
  end
end

def test_index_search_sorted(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('green')

  # Should be sorted descending by score
  if results.length > 1
    assert.true! results[0][:score] >= results[1][:score]
  end
end

def test_index_search_field(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('title:plant')

  # Should find docs with 'plant' in title
  assert.true! results.length > 0
end

def test_index_search_no_results(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('nonexistent')

  assert.equal! results.length, 0
end

def test_index_search_required(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('+green')

  # Should only return docs with 'green'
  assert.true! results.length > 0
  results.each do |result|
    assert.true! ['a', 'b'].include?(result[:ref])
  end
end

def test_index_search_prohibited(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('plant -study')

  # Should have docs with 'plant' but not 'study'
  # Doc 'b' has both plant and study, so should be excluded
  # Doc 'a' has plant but not study, so should be included
  refs = results.map { |r| r[:ref] }
  assert.true! refs.include?('a')
  assert.false! refs.include?('b')
end

def test_index_search_trailing_wildcard(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('gre*')

  assert.true! results.length > 0, "Should find documents matching 'gre*'"
  refs = results.map { |r| r[:ref] }
  assert.true! refs.include?('a') || refs.include?('b'), "Should find docs with 'green'"
end

def test_index_search_leading_wildcard(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('*een')

  assert.true! results.length > 0, "Should find documents matching '*een'"
  refs = results.map { |r| r[:ref] }
  assert.true! refs.include?('a') || refs.include?('b'), "Should find docs with 'green'"
end

def test_index_search_contained_wildcard(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('gr*en')

  assert.true! results.length > 0, "Should find documents matching 'gr*en'"
  refs = results.map { |r| r[:ref] }
  assert.true! refs.include?('a') || refs.include?('b'), "Should find docs with 'green'"
end

def test_index_search_wildcard_multiple_matches(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  # '*' alone matches everything (leading+trailing wildcard pattern)
  # 'pl*' should match 'plant'
  results = index.search('pl*')
  assert.true! results.length > 0, "Should find documents matching 'pl*'"
end

def test_index_search_fuzzy(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  # 'grean' is 1 edit from 'green' (substitution: e->a)
  results = index.search('grean~1')
  assert.true! results.length > 0, "Should find documents matching 'grean~1'"
  refs = results.map { |r| r[:ref] }
  assert.true! refs.include?('a') || refs.include?('b'), "Should find docs with 'green'"
end

def test_index_search_fuzzy_no_match(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('zzzzz~1')
  assert.equal! results.length, 0, "Should find no documents for 'zzzzz~1'"
end

def test_index_search_wildcard_no_match(_args, assert)
  data = get_test_index_data
  index = LunrQuery::Index.load(data)

  results = index.search('xyz*')
  assert.equal! results.length, 0, "Should find no documents for 'xyz*'"
end

# --- Stemmed index tests (wildcard/fuzzy + pipeline interaction) ---

# Stemmed test index fixture (as Lunr.js would produce with stemmer pipeline)
def get_stemmed_test_index_data
  {
    'version' => '2.3.9',
    'fields' => ['title', 'body'],
    'fieldVectors' => [
      ['title/a', [0, 0.5]],
      ['body/a', [0, 0.8, 1, 0.4]],
      ['title/b', [1, 0.6]]
    ],
    'invertedIndex' => [
      ['command', {
        '_index' => 0,
        'title' => { 'a' => { 'position' => [1] } },
        'body' => { 'a' => { 'position' => [3] } }
      }],
      ['walk', {
        '_index' => 1,
        'body' => { 'a' => { 'position' => [8] } },
        'title' => { 'b' => { 'position' => [1] } }
      }]
    ],
    'pipeline' => ['stemmer']
  }
end

def test_index_search_wildcard_stemmer_trailing(_args, assert)
  index = LunrQuery::Index.load(get_stemmed_test_index_data)

  # "commande*" -> stem("commande") -> "command" -> "command*" matches "command"
  results = index.search('commande*')
  assert.true! results.length > 0, "Should find 'command' when searching 'commande*' with stemmer"
end

def test_index_search_wildcard_stemmer_leading(_args, assert)
  index = LunrQuery::Index.load(get_stemmed_test_index_data)

  # "*alking" -> stem("alking") -> "alk" -> "*alk" matches "walk"
  results = index.search('*alking')
  assert.true! results.length > 0, "Should find 'walk' when searching '*alking' with stemmer"
end

def test_index_search_fuzzy_stemmer(_args, assert)
  index = LunrQuery::Index.load(get_stemmed_test_index_data)

  # "commanded" -> stem -> "command" -> fuzzy match "command" (distance 0)
  results = index.search('commanded~1')
  assert.true! results.length > 0, "Should find 'command' when fuzzy searching 'commanded~1' with stemmer"
end

def test_index_search_wildcard_empty_pipeline(_args, assert)
  index = LunrQuery::Index.load(get_test_index_data)

  results = index.search('gre*')
  assert.true! results.length > 0, "Should still find 'green' with empty pipeline"
end

def test_index_empty(_args, assert)
  data = {
    'fields' => ['title'],
    'fieldVectors' => [],
    'invertedIndex' => [],
    'pipeline' => []
  }

  index = LunrQuery::Index.load(data)
  results = index.search('anything')

  assert.equal! results.length, 0
end
