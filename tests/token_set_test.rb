require 'lib/lunr_query/token_set.rb'

def test_token_set_from_string(_args, assert)
  token_set = LunrQuery::TokenSet.from_string('hello')

  # Should have path: h -> e -> l -> l -> o (final)
  assert.true! token_set.edges.key?('h')

  node = token_set.edges['h']
  assert.true! node.edges.key?('e')

  node = node.edges['e']
  assert.true! node.edges.key?('l')

  node = node.edges['l']
  assert.true! node.edges.key?('l')

  node = node.edges['l']
  assert.true! node.edges.key?('o')

  node = node.edges['o']
  assert.true! node.final
end

def test_token_set_to_array(_args, assert)
  token_set = LunrQuery::TokenSet.from_string('cat')
  words = token_set.to_array

  assert.equal! words.length, 1
  assert.equal! words[0], 'cat'
end

def test_token_set_from_array_sorted(_args, assert)
  token_set = LunrQuery::TokenSet.from_array(['cat', 'dog', 'fish'])
  words = token_set.to_array.sort

  assert.equal! words, ['cat', 'dog', 'fish']
end

def test_token_set_from_array_unsorted(_args, assert)
  raised = false
  begin
    LunrQuery::TokenSet.from_array(['zebra', 'apple'])
  rescue => e
    raised = true
  end
  assert.true! raised, "Should raise error for unsorted array"
end

def test_token_set_intersect(_args, assert)
  set1 = LunrQuery::TokenSet.from_array(['cat', 'dog'])
  set2 = LunrQuery::TokenSet.from_array(['dog', 'fish'])

  result = set1.intersect(set2)
  words = result.to_array

  assert.equal! words.length, 1
  assert.equal! words[0], 'dog'
end

def test_token_set_intersect_no_common(_args, assert)
  set1 = LunrQuery::TokenSet.from_array(['cat'])
  set2 = LunrQuery::TokenSet.from_array(['dog'])

  result = set1.intersect(set2)
  words = result.to_array

  assert.equal! words.length, 0
end

def test_token_set_intersect_same(_args, assert)
  set1 = LunrQuery::TokenSet.from_array(['cat', 'dog'])
  set2 = LunrQuery::TokenSet.from_array(['cat', 'dog'])

  result = set1.intersect(set2)
  words = result.to_array.sort

  assert.equal! words, ['cat', 'dog']
end

def test_token_set_from_clause(_args, assert)
  clause = { term: 'hello' }
  token_set = LunrQuery::TokenSet.from_clause(clause)

  words = token_set.to_array
  assert.equal! words, ['hello']
end

def test_token_set_from_clause_with_edit_distance(_args, assert)
  clause = { term: 'hello', edit_distance: 2 }
  token_set = LunrQuery::TokenSet.from_clause(clause)

  assert.equal! token_set.fuzzy_term, 'hello'
  assert.equal! token_set.fuzzy_distance, 2
end

def test_token_set_builder_shared_prefix(_args, assert)
  token_set = LunrQuery::TokenSet.from_array(['cat', 'cats', 'dog'])
  words = token_set.to_array.sort

  assert.equal! words, ['cat', 'cats', 'dog']
end

def test_token_set_empty(_args, assert)
  token_set = LunrQuery::TokenSet.new
  words = token_set.to_array

  assert.equal! words.length, 0
end

# --- Wildcard Tests ---

def test_token_set_from_string_trailing_wildcard(_args, assert)
  token_set = LunrQuery::TokenSet.from_string('foo*')
  assert.equal! token_set.wildcard_pattern, 'foo*'
end

def test_token_set_from_string_leading_wildcard(_args, assert)
  token_set = LunrQuery::TokenSet.from_string('*oo')
  assert.equal! token_set.wildcard_pattern, '*oo'
end

def test_token_set_from_string_contained_wildcard(_args, assert)
  token_set = LunrQuery::TokenSet.from_string('f*o')
  assert.equal! token_set.wildcard_pattern, 'f*o'
end

def test_token_set_from_string_multiple_wildcards_raises(_args, assert)
  raised = false
  begin
    LunrQuery::TokenSet.from_string('f*o*')
  rescue => e
    raised = true
    assert.true! e.message.include?('Only one wildcard'), "Error should mention single wildcard restriction"
  end
  assert.true! raised, "Should raise error for multiple wildcards"
end

def test_token_set_intersect_trailing_wildcard(_args, assert)
  index_set = LunrQuery::TokenSet.from_array(['cat', 'catch', 'dog'])
  query_set = LunrQuery::TokenSet.from_string('cat*')

  result = index_set.intersect(query_set)
  words = result.to_array.sort

  assert.equal! words, ['cat', 'catch']
end

def test_token_set_intersect_leading_wildcard(_args, assert)
  index_set = LunrQuery::TokenSet.from_array(['bat', 'cat', 'dog'])
  query_set = LunrQuery::TokenSet.from_string('*at')

  result = index_set.intersect(query_set)
  words = result.to_array.sort

  assert.equal! words, ['bat', 'cat']
end

def test_token_set_intersect_contained_wildcard(_args, assert)
  index_set = LunrQuery::TokenSet.from_array(['can', 'cat', 'con', 'cut', 'dog'])
  query_set = LunrQuery::TokenSet.from_string('c*t')

  result = index_set.intersect(query_set)
  words = result.to_array.sort

  assert.equal! words, ['cat', 'cut']
end

def test_token_set_intersect_wildcard_no_match(_args, assert)
  index_set = LunrQuery::TokenSet.from_array(['cat', 'dog'])
  query_set = LunrQuery::TokenSet.from_string('fish*')

  result = index_set.intersect(query_set)
  words = result.to_array

  assert.equal! words.length, 0
end

# --- Fuzzy Matching Tests ---

def test_token_set_levenshtein_exact(_args, assert)
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('car', 'car'), 0
end

def test_token_set_levenshtein_substitution(_args, assert)
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('car', 'bar'), 1
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('car', 'cur'), 1
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('car', 'cat'), 1
end

def test_token_set_levenshtein_insertion(_args, assert)
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('bar', 'bbar'), 1
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('bar', 'baar'), 1
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('bar', 'barr'), 1
end

def test_token_set_levenshtein_deletion(_args, assert)
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('bar', 'ar'), 1
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('bar', 'br'), 1
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('bar', 'ba'), 1
end

def test_token_set_levenshtein_transposition(_args, assert)
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('bar', 'abr'), 1
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('bar', 'bra'), 1
end

def test_token_set_levenshtein_multiple(_args, assert)
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('abc', 'abcxx'), 2
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('abc', 'axx'), 2
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('abc', 'a'), 2
  assert.equal! LunrQuery::TokenSet.levenshtein_distance('abc', 'bca'), 2
end

def test_token_set_intersect_fuzzy_substitution(_args, assert)
  index_set = LunrQuery::TokenSet.from_array(['bar', 'car', 'cat', 'cur', 'foo'])
  query_set = LunrQuery::TokenSet.from_fuzzy_string('car', 1)

  result = index_set.intersect(query_set)
  words = result.to_array.sort

  assert.true! words.include?('bar'), "Should match 'bar' (c->b substitution)"
  assert.true! words.include?('cur'), "Should match 'cur' (a->u substitution)"
  assert.true! words.include?('cat'), "Should match 'cat' (r->t substitution)"
  assert.true! words.include?('car'), "Should match 'car' (exact)"
  assert.false! words.include?('foo'), "Should not match 'foo'"
end

def test_token_set_intersect_fuzzy_deletion(_args, assert)
  index_set = LunrQuery::TokenSet.from_array(['ar', 'ba', 'bar', 'br', 'foo'])
  query_set = LunrQuery::TokenSet.from_fuzzy_string('bar', 1)

  result = index_set.intersect(query_set)
  words = result.to_array.sort

  assert.true! words.include?('ar'), "Should match 'ar' (delete 'b')"
  assert.true! words.include?('br'), "Should match 'br' (delete 'a')"
  assert.true! words.include?('ba'), "Should match 'ba' (delete 'r')"
  assert.true! words.include?('bar'), "Should match 'bar' (exact)"
  assert.false! words.include?('foo'), "Should not match 'foo'"
end

def test_token_set_intersect_fuzzy_insertion(_args, assert)
  index_set = LunrQuery::TokenSet.from_array(['ba', 'baar', 'bar', 'bara', 'barr', 'bbar', 'foo'])
  query_set = LunrQuery::TokenSet.from_fuzzy_string('bar', 1)

  result = index_set.intersect(query_set)
  words = result.to_array.sort

  assert.true! words.include?('bbar'), "Should match 'bbar' (insert 'b')"
  assert.true! words.include?('baar'), "Should match 'baar' (insert 'a')"
  assert.true! words.include?('barr'), "Should match 'barr' (insert 'r')"
  assert.true! words.include?('bar'), "Should match 'bar' (exact)"
  assert.true! words.include?('ba'), "Should match 'ba' (deletion)"
  assert.true! words.include?('bara'), "Should match 'bara' (insert at end)"
  assert.false! words.include?('foo'), "Should not match 'foo'"
end

def test_token_set_intersect_fuzzy_transposition(_args, assert)
  index_set = LunrQuery::TokenSet.from_array(['abr', 'bar', 'bra', 'foo'])
  query_set = LunrQuery::TokenSet.from_fuzzy_string('bar', 1)

  result = index_set.intersect(query_set)
  words = result.to_array.sort

  assert.true! words.include?('abr'), "Should match 'abr' (transpose ba->ab)"
  assert.true! words.include?('bra'), "Should match 'bra' (transpose ar->ra)"
  assert.true! words.include?('bar'), "Should match 'bar' (exact)"
  assert.false! words.include?('foo'), "Should not match 'foo'"
end

def test_token_set_intersect_fuzzy_distance_2(_args, assert)
  query_set = LunrQuery::TokenSet.from_fuzzy_string('abc', 2)

  # 2 insertions
  set1 = LunrQuery::TokenSet.from_array(['abcxx'])
  assert.equal! set1.intersect(query_set).to_array, ['abcxx']

  # 2 substitutions
  set2 = LunrQuery::TokenSet.from_array(['axx'])
  assert.equal! set2.intersect(query_set).to_array, ['axx']

  # 2 deletions
  set3 = LunrQuery::TokenSet.from_array(['a'])
  assert.equal! set3.intersect(query_set).to_array, ['a']

  # 2 transpositions
  set4 = LunrQuery::TokenSet.from_array(['bca'])
  assert.equal! set4.intersect(query_set).to_array, ['bca']
end
