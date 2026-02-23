require 'lib/lunr_query.rb'

# TODO: update to use the astronaut sample

def test_integration_full_search_flow(_args, assert)
  # Create a more realistic test index
  data = {
    'version' => '2.3.9',
    'fields' => ['title', 'author', 'body'],
    'fieldVectors' => [
      ['title/doc1', [0, 0.5, 1, 0.3]],    # green, plant
      ['author/doc1', [2, 0.2]],            # smith
      ['body/doc1', [0, 0.8, 1, 0.4]],     # green, plant
      ['title/doc2', [1, 0.6, 3, 0.5]],    # plant, study
      ['body/doc2', [0, 0.4, 3, 0.7]],     # green, study
      ['title/doc3', [4, 0.9]],             # flower
      ['body/doc3', [4, 0.8, 1, 0.3]]      # flower, plant
    ],
    'invertedIndex' => [
      ['green', {
        '_index' => 0,
        'title' => { 'doc1' => { 'position' => [1] } },
        'body' => { 'doc1' => { 'position' => [3] }, 'doc2' => { 'position' => [5] } }
      }],
      ['plant', {
        '_index' => 1,
        'title' => { 'doc1' => { 'position' => [2] }, 'doc2' => { 'position' => [1] } },
        'body' => { 'doc1' => { 'position' => [8] }, 'doc3' => { 'position' => [4] } }
      }],
      ['smith', {
        '_index' => 2,
        'author' => { 'doc1' => { 'position' => [1] } }
      }],
      ['study', {
        '_index' => 3,
        'title' => { 'doc2' => { 'position' => [3] } },
        'body' => { 'doc2' => { 'position' => [8] } }
      }],
      ['flower', {
        '_index' => 4,
        'title' => { 'doc3' => { 'position' => [1] } },
        'body' => { 'doc3' => { 'position' => [2] } }
      }]
    ],
    'pipeline' => []
  }

  index = LunrQuery::Index.load(data)

  results = index.search('green')
  assert.true! results.length > 0, "Should find documents with 'green'"
  refs = results.map { |r| r[:ref] }
  assert.true! refs.include?('doc1') || refs.include?('doc2'), "Should include doc1 or doc2"

  results = index.search('title:plant')
  assert.true! results.length > 0, "Should find documents with 'plant' in title"
  refs = results.map { |r| r[:ref] }
  assert.true! refs.include?('doc1') || refs.include?('doc2'), "Should find docs with plant in title"

  results = index.search('green plant')
  assert.true! results.length > 0, "Should find documents with either term"

  results = index.search('+green +plant')
  assert.true! results.length > 0, "Should find documents with both terms"
  results.each do |result|
    assert.true! ['doc1', 'doc2'].include?(result[:ref]), "Only doc1 and doc2 have both green and plant"
  end

  results = index.search('plant -study')
  refs = results.map { |r| r[:ref] }
  assert.false! refs.include?('doc2'), "doc2 should be excluded (has study)"
  assert.true! refs.include?('doc1') || refs.include?('doc3'), "doc1 or doc3 should be included"
end

def test_integration_empty_search(_args, assert)
  data = {
    'fields' => ['title'],
    'fieldVectors' => [],
    'invertedIndex' => [],
    'pipeline' => []
  }

  index = LunrQuery::Index.load(data)
  results = index.search('anything')
  assert.equal! results.length, 0, "Empty index should return no results"
end

def test_integration_no_matches(_args, assert)
  data = {
    'fields' => ['title'],
    'fieldVectors' => [
      ['title/doc1', [0, 0.5]]
    ],
    'invertedIndex' => [
      ['hello', {
        '_index' => 0,
        'title' => { 'doc1' => { 'position' => [1] } }
      }]
    ],
    'pipeline' => []
  }

  index = LunrQuery::Index.load(data)
  results = index.search('goodbye')
  assert.equal! results.length, 0, "Should return no results for non-existent term"
end

def test_integration_field_and_presence(_args, assert)
  data = {
    'fields' => ['title', 'body'],
    'fieldVectors' => [
      ['title/doc1', [0, 0.5]],
      ['body/doc1', [1, 0.8]],
      ['title/doc2', [0, 0.6, 1, 0.4]],
      ['body/doc2', [1, 0.7]]
    ],
    'invertedIndex' => [
      ['apple', {
        '_index' => 0,
        'title' => { 'doc1' => { 'position' => [1] }, 'doc2' => { 'position' => [1] } }
      }],
      ['orange', {
        '_index' => 1,
        'body' => { 'doc1' => { 'position' => [3] }, 'doc2' => { 'position' => [5] } },
        'title' => { 'doc2' => { 'position' => [2] } }
      }]
    ],
    'pipeline' => []
  }

  index = LunrQuery::Index.load(data)

  results = index.search('title:apple +orange')
  assert.true! results.length > 0, "Should find documents"

  refs = results.map { |r| r[:ref] }
  assert.true! refs.include?('doc1') || refs.include?('doc2'), "Should find matching docs"
end

def test_integration_stopwords(_args, assert)
  data = {
    'fields' => ['body'],
    'fieldVectors' => [
      ['body/doc1', [0, 0.8]],   # keyword
      ['body/doc2', [0, 0.6]]    # keyword
    ],
    'invertedIndex' => [
      ['keyword', {
        '_index' => 0,
        'body' => {
          'doc1' => { 'position' => [1] },
          'doc2' => { 'position' => [1] }
        }
      }]
    ],
    'pipeline' => ['stopWordFilter']
  }

  index = LunrQuery::Index.load(data)

  results = index.search('the')
  assert.equal! results.length, 0, "Stopword 'the' should return no results"

  results = index.search('keyword')
  assert.equal! results.length, 2, "Non-stopword should find documents"
end

def test_integration_scoring_order(_args, assert)
  data = {
    'fields' => ['body'],
    'fieldVectors' => [
      ['body/doc1', [0, 0.9]],   # High relevance
      ['body/doc2', [0, 0.3]],   # Low relevance
      ['body/doc3', [0, 0.6]]    # Medium relevance
    ],
    'invertedIndex' => [
      ['keyword', {
        '_index' => 0,
        'body' => {
          'doc1' => { 'position' => [1] },
          'doc2' => { 'position' => [1] },
          'doc3' => { 'position' => [1] }
        }
      }]
    ],
    'pipeline' => []
  }

  index = LunrQuery::Index.load(data)
  results = index.search('keyword')

  assert.equal! results.length, 3, "Should find all 3 documents"

  assert.true! results[0][:score] >= results[1][:score], "First result should have highest score"
  assert.true! results[1][:score] >= results[2][:score], "Second result should have higher score than third"

  assert.equal! results[0][:ref], 'doc1', "doc1 should rank highest"
end
