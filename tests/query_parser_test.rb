require 'lib/lunr_query/query.rb'
require 'lib/lunr_query/query_lexer.rb'
require 'lib/lunr_query/query_parser.rb'

ALL_FIELDS = ['title', 'body']

def parse_query(q)
  query = LunrQuery::Query.new(ALL_FIELDS)
  parser = LunrQuery::QueryParser.new(q, query)
  parser.parse
  query.clauses
end

def test_query_parser_single_term(_args, assert)
  clauses = parse_query('foo')

  assert.equal! clauses.length, 1
  assert.equal! clauses[0][:term], 'foo'
  assert.equal! clauses[0][:fields], ALL_FIELDS
  assert.equal! clauses[0][:presence], LunrQuery::Query::PRESENCE_OPTIONAL
  assert.true! clauses[0][:use_pipeline]
end

def test_query_parser_uppercase_term(_args, assert)
  clauses = parse_query('FOO')

  assert.equal! clauses.length, 1
  assert.equal! clauses[0][:term], 'foo'
end

def test_query_parser_wildcard(_args, assert)
  clauses = parse_query('fo*')

  assert.equal! clauses.length, 1
  assert.equal! clauses[0][:term], 'fo*'
  assert.false! clauses[0][:use_pipeline]
end

def test_query_parser_multiple_terms(_args, assert)
  clauses = parse_query('foo bar')

  assert.equal! clauses.length, 2
  assert.equal! clauses[0][:term], 'foo'
  assert.equal! clauses[1][:term], 'bar'
end

def test_query_parser_field(_args, assert)
  clauses = parse_query('title:foo')

  assert.equal! clauses.length, 1
  assert.equal! clauses[0][:term], 'foo'
  assert.equal! clauses[0][:fields], ['title']
end

def test_query_parser_presence_required(_args, assert)
  clauses = parse_query('+foo')

  assert.equal! clauses.length, 1
  assert.equal! clauses[0][:term], 'foo'
  assert.equal! clauses[0][:presence], LunrQuery::Query::PRESENCE_REQUIRED
end

def test_query_parser_presence_prohibited(_args, assert)
  clauses = parse_query('-bar')

  assert.equal! clauses.length, 1
  assert.equal! clauses[0][:term], 'bar'
  assert.equal! clauses[0][:presence], LunrQuery::Query::PRESENCE_PROHIBITED
end

def test_query_parser_boost(_args, assert)
  clauses = parse_query('foo^10')

  assert.equal! clauses.length, 1
  assert.equal! clauses[0][:term], 'foo'
  assert.equal! clauses[0][:boost], 10
end

def test_query_parser_edit_distance(_args, assert)
  clauses = parse_query('foo~2')

  assert.equal! clauses.length, 1
  assert.equal! clauses[0][:term], 'foo'
  assert.equal! clauses[0][:edit_distance], 2
end

def test_query_parser_combined(_args, assert)
  clauses = parse_query('title:foo^5 +bar -baz')

  assert.equal! clauses.length, 3

  # First clause: field + boost
  assert.equal! clauses[0][:term], 'foo'
  assert.equal! clauses[0][:fields], ['title']
  assert.equal! clauses[0][:boost], 5

  # Second clause: required
  assert.equal! clauses[1][:term], 'bar'
  assert.equal! clauses[1][:presence], LunrQuery::Query::PRESENCE_REQUIRED

  # Third clause: prohibited
  assert.equal! clauses[2][:term], 'baz'
  assert.equal! clauses[2][:presence], LunrQuery::Query::PRESENCE_PROHIBITED
end

def test_query_parser_field_with_presence(_args, assert)
  clauses = parse_query('+title:foo')

  assert.equal! clauses.length, 1
  assert.equal! clauses[0][:term], 'foo'
  assert.equal! clauses[0][:fields], ['title']
  assert.equal! clauses[0][:presence], LunrQuery::Query::PRESENCE_REQUIRED
end

def test_query_parser_boost_and_edit_distance(_args, assert)
  clauses = parse_query('foo~2^10')

  assert.equal! clauses.length, 1
  assert.equal! clauses[0][:term], 'foo'
  assert.equal! clauses[0][:edit_distance], 2
  assert.equal! clauses[0][:boost], 10
end

def test_query_parser_invalid_field(_args, assert)
  raised = false
  begin
    parse_query('unknown:foo')
  rescue => e
    raised = true
    assert.true! e.to_s.include?('unrecognised field')
  end
  assert.true! raised, "Should raise error for invalid field"
end
