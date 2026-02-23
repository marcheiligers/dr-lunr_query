require 'lib/lunr_query/query_lexer.rb'

def lex(str)
  lexer = LunrQuery::QueryLexer.new(str)
  lexer.run
  lexer
end

def test_query_lexer_single_term(_args, assert)
  lexer = lex('foo')
  assert.equal! lexer.lexemes.length, 2 # TERM + EOS
  assert.equal! lexer.lexemes[0][:type], LunrQuery::QueryLexer::TERM
  assert.equal! lexer.lexemes[0][:str], 'foo'
  assert.equal! lexer.lexemes[0][:start], 0
  assert.equal! lexer.lexemes[0][:end], 3
end

def test_query_lexer_multiple_terms(_args, assert)
  lexer = lex('foo bar')
  assert.equal! lexer.lexemes.length, 3 # TERM + TERM + EOS

  assert.equal! lexer.lexemes[0][:type], LunrQuery::QueryLexer::TERM
  assert.equal! lexer.lexemes[0][:str], 'foo'
  assert.equal! lexer.lexemes[0][:start], 0
  assert.equal! lexer.lexemes[0][:end], 3

  assert.equal! lexer.lexemes[1][:type], LunrQuery::QueryLexer::TERM
  assert.equal! lexer.lexemes[1][:str], 'bar'
  assert.equal! lexer.lexemes[1][:start], 4
  assert.equal! lexer.lexemes[1][:end], 7
end

def test_query_lexer_term_with_hyphen(_args, assert)
  lexer = lex('foo-bar')
  assert.equal! lexer.lexemes.length, 3 # TERM + TERM + EOS

  assert.equal! lexer.lexemes[0][:str], 'foo'
  assert.equal! lexer.lexemes[1][:str], 'bar'
end

def test_query_lexer_escape_character(_args, assert)
  lexer = lex('foo\\:bar')
  assert.equal! lexer.lexemes.length, 2 # TERM + EOS

  assert.equal! lexer.lexemes[0][:type], LunrQuery::QueryLexer::TERM
  assert.equal! lexer.lexemes[0][:str], 'foo:bar'
end

def test_query_lexer_field(_args, assert)
  lexer = lex('title:foo')
  assert.equal! lexer.lexemes.length, 3 # FIELD + TERM + EOS

  assert.equal! lexer.lexemes[0][:type], LunrQuery::QueryLexer::FIELD
  assert.equal! lexer.lexemes[0][:str], 'title'

  assert.equal! lexer.lexemes[1][:type], LunrQuery::QueryLexer::TERM
  assert.equal! lexer.lexemes[1][:str], 'foo'
end

def test_query_lexer_presence_required(_args, assert)
  lexer = lex('+foo')
  assert.equal! lexer.lexemes.length, 3 # PRESENCE + TERM + EOS

  assert.equal! lexer.lexemes[0][:type], LunrQuery::QueryLexer::PRESENCE
  assert.equal! lexer.lexemes[0][:str], '+'

  assert.equal! lexer.lexemes[1][:type], LunrQuery::QueryLexer::TERM
  assert.equal! lexer.lexemes[1][:str], 'foo'
end

def test_query_lexer_presence_prohibited(_args, assert)
  lexer = lex('-bar')
  assert.equal! lexer.lexemes.length, 3 # PRESENCE + TERM + EOS

  assert.equal! lexer.lexemes[0][:type], LunrQuery::QueryLexer::PRESENCE
  assert.equal! lexer.lexemes[0][:str], '-'

  assert.equal! lexer.lexemes[1][:type], LunrQuery::QueryLexer::TERM
  assert.equal! lexer.lexemes[1][:str], 'bar'
end

def test_query_lexer_boost(_args, assert)
  lexer = lex('foo^10')
  assert.equal! lexer.lexemes.length, 3 # TERM + BOOST + EOS

  assert.equal! lexer.lexemes[0][:type], LunrQuery::QueryLexer::TERM
  assert.equal! lexer.lexemes[0][:str], 'foo'

  assert.equal! lexer.lexemes[1][:type], LunrQuery::QueryLexer::BOOST
  assert.equal! lexer.lexemes[1][:str], '10'
end

def test_query_lexer_edit_distance(_args, assert)
  lexer = lex('foo~2')
  assert.equal! lexer.lexemes.length, 3 # TERM + EDIT_DISTANCE + EOS

  assert.equal! lexer.lexemes[0][:type], LunrQuery::QueryLexer::TERM
  assert.equal! lexer.lexemes[0][:str], 'foo'

  assert.equal! lexer.lexemes[1][:type], LunrQuery::QueryLexer::EDIT_DISTANCE
  assert.equal! lexer.lexemes[1][:str], '2'
end

def test_query_lexer_combined(_args, assert)
  lexer = lex('title:foo^5 +bar -baz')

  types = lexer.lexemes.map { |l| l[:type] }
  expected = [
    LunrQuery::QueryLexer::FIELD,
    LunrQuery::QueryLexer::TERM,
    LunrQuery::QueryLexer::BOOST,
    LunrQuery::QueryLexer::PRESENCE,
    LunrQuery::QueryLexer::TERM,
    LunrQuery::QueryLexer::PRESENCE,
    LunrQuery::QueryLexer::TERM,
    LunrQuery::QueryLexer::EOS
  ]

  assert.equal! types, expected
end

def test_query_lexer_eos(_args, assert)
  lexer = lex('foo')
  last = lexer.lexemes.last

  assert.equal! last[:type], LunrQuery::QueryLexer::EOS
end
