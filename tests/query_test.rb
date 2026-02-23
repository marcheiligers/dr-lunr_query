require 'lib/lunr_query/query.rb'

ALL_FIELDS = ['title', 'body']

def test_query_term_single_string(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.term('foo')

  assert.equal! query.clauses.length, 1
  assert.equal! query.clauses[0][:term], 'foo'
end

def test_query_term_multiple_strings(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.term(['foo', 'bar'])

  assert.equal! query.clauses.length, 2
  terms = query.clauses.map { |c| c[:term] }.sort
  assert.equal! terms, ['bar', 'foo']
end

def test_query_term_with_options(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.term(['foo', 'bar'], { use_pipeline: false })

  assert.equal! query.clauses.length, 2
  assert.false! query.clauses[0][:use_pipeline]
  assert.false! query.clauses[1][:use_pipeline]
end

def test_query_clause_defaults(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.clause({ term: 'foo' })

  clause = query.clauses[0]
  assert.equal! clause[:fields], ALL_FIELDS
  assert.equal! clause[:boost], 1
  assert.true! clause[:use_pipeline]
  assert.equal! clause[:wildcard], LunrQuery::Query::WILDCARD_NONE
  assert.equal! clause[:presence], LunrQuery::Query::PRESENCE_OPTIONAL
end

def test_query_clause_specified(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.clause({
    term: 'foo',
    boost: 10,
    fields: ['title'],
    use_pipeline: false
  })

  clause = query.clauses[0]
  assert.equal! clause[:fields], ['title']
  assert.equal! clause[:boost], 10
  assert.false! clause[:use_pipeline]
end

def test_query_wildcard_none(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.clause({
    term: 'foo',
    wildcard: LunrQuery::Query::WILDCARD_NONE
  })

  assert.equal! query.clauses[0][:term], 'foo'
end

def test_query_wildcard_leading(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.clause({
    term: 'foo',
    wildcard: LunrQuery::Query::WILDCARD_LEADING
  })

  assert.equal! query.clauses[0][:term], '*foo'
end

def test_query_wildcard_trailing(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.clause({
    term: 'foo',
    wildcard: LunrQuery::Query::WILDCARD_TRAILING
  })

  assert.equal! query.clauses[0][:term], 'foo*'
end

def test_query_wildcard_leading_and_trailing(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.clause({
    term: 'foo',
    wildcard: LunrQuery::Query::WILDCARD_LEADING | LunrQuery::Query::WILDCARD_TRAILING
  })

  assert.equal! query.clauses[0][:term], '*foo*'
end

def test_query_wildcard_existing(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.clause({
    term: '*foo*',
    wildcard: LunrQuery::Query::WILDCARD_LEADING | LunrQuery::Query::WILDCARD_TRAILING
  })

  assert.equal! query.clauses[0][:term], '*foo*'
end

def test_query_is_negated_false(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.clause({ term: 'foo', presence: LunrQuery::Query::PRESENCE_REQUIRED })
  query.clause({ term: 'bar', presence: LunrQuery::Query::PRESENCE_PROHIBITED })

  assert.false! query.is_negated?
end

def test_query_is_negated_true(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)
  query.clause({ term: 'foo', presence: LunrQuery::Query::PRESENCE_PROHIBITED })
  query.clause({ term: 'bar', presence: LunrQuery::Query::PRESENCE_PROHIBITED })

  assert.true! query.is_negated?
end

def test_query_is_negated_empty(_args, assert)
  query = LunrQuery::Query.new(ALL_FIELDS)

  assert.false! query.is_negated?
end

def test_query_presence_constants(_args, assert)
  assert.equal! LunrQuery::Query::PRESENCE_OPTIONAL, 1
  assert.equal! LunrQuery::Query::PRESENCE_REQUIRED, 2
  assert.equal! LunrQuery::Query::PRESENCE_PROHIBITED, 3
end

def test_query_wildcard_constants(_args, assert)
  assert.equal! LunrQuery::Query::WILDCARD_NONE, 0
  assert.equal! LunrQuery::Query::WILDCARD_LEADING, 1
  assert.equal! LunrQuery::Query::WILDCARD_TRAILING, 2
end
