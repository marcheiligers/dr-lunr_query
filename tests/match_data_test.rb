require 'lib/lunr_query/match_data.rb'

def test_match_data_combine_terms(_args, assert)
  match = LunrQuery::MatchData.new('foo', 'title', { 'position' => [1] })
  match.combine(LunrQuery::MatchData.new('bar', 'title', { 'position' => [2] }))
  match.combine(LunrQuery::MatchData.new('baz', 'body', { 'position' => [3] }))
  match.combine(LunrQuery::MatchData.new('baz', 'body', { 'position' => [4] }))

  terms = match.metadata.keys.sort
  assert.equal! terms, ['bar', 'baz', 'foo']
end

def test_match_data_combine_metadata(_args, assert)
  match = LunrQuery::MatchData.new('foo', 'title', { 'position' => [1] })
  match.combine(LunrQuery::MatchData.new('bar', 'title', { 'position' => [2] }))
  match.combine(LunrQuery::MatchData.new('baz', 'body', { 'position' => [3] }))
  match.combine(LunrQuery::MatchData.new('baz', 'body', { 'position' => [4] }))

  assert.equal! match.metadata['foo']['title']['position'], [1]
  assert.equal! match.metadata['bar']['title']['position'], [2]
  assert.equal! match.metadata['baz']['body']['position'], [3, 4]
end

def test_match_data_does_not_mutate_source(_args, assert)
  metadata = { 'foo' => [1] }
  match_data1 = LunrQuery::MatchData.new('foo', 'title', metadata)
  match_data2 = LunrQuery::MatchData.new('foo', 'title', metadata)

  match_data1.combine(match_data2)

  # Original metadata should not be mutated
  assert.equal! metadata['foo'], [1]
end

def test_match_data_add_new_term(_args, assert)
  match = LunrQuery::MatchData.new
  match.add('foo', 'title', { 'position' => [1, 2] })

  assert.equal! match.metadata['foo']['title']['position'], [1, 2]
end

def test_match_data_add_new_field(_args, assert)
  match = LunrQuery::MatchData.new('foo', 'title', { 'position' => [1] })
  match.add('foo', 'body', { 'position' => [2] })

  assert.equal! match.metadata['foo']['title']['position'], [1]
  assert.equal! match.metadata['foo']['body']['position'], [2]
end

def test_match_data_add_to_existing(_args, assert)
  match = LunrQuery::MatchData.new('foo', 'title', { 'position' => [1] })
  match.add('foo', 'title', { 'position' => [2] })

  assert.equal! match.metadata['foo']['title']['position'], [1, 2]
end

def test_match_data_add_multiple_metadata_keys(_args, assert)
  match = LunrQuery::MatchData.new
  match.add('foo', 'title', { 'position' => [1], 'score' => [0.5] })
  match.add('foo', 'title', { 'position' => [2], 'score' => [0.8] })

  assert.equal! match.metadata['foo']['title']['position'], [1, 2]
  assert.equal! match.metadata['foo']['title']['score'], [0.5, 0.8]
end
