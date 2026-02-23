require 'lib/lunr_query.rb'

def test_stemmer_registered(_args, assert)
  fn = LunrQuery::Pipeline.get_function('stemmer')
  assert.true! fn != nil, "Stemmer should be registered"
end

def test_stemmer_short_words(_args, assert)
  stemmer = LunrQuery::STEMMER
  assert.equal! stemmer.call('a'), 'a'
  assert.equal! stemmer.call('is'), 'is'
  assert.equal! stemmer.call('to'), 'to'
end

def test_stemmer_basic_suffixes(_args, assert)
  stemmer = LunrQuery::STEMMER

  # -ing suffix
  assert.equal! stemmer.call('running'), 'run'
  assert.equal! stemmer.call('walking'), 'walk'

  # -ed suffix
  assert.equal! stemmer.call('walked'), 'walk'
  assert.equal! stemmer.call('played'), 'play'

  # -s suffix
  assert.equal! stemmer.call('cats'), 'cat'
  assert.equal! stemmer.call('dogs'), 'dog'
end

def test_stemmer_ies_suffix(_args, assert)
  stemmer = LunrQuery::STEMMER
  assert.equal! stemmer.call('berries'), 'berri'
  assert.equal! stemmer.call('flies'), 'fli'
end

# step1c: y->i only when preceded by a non-vowel that is not the first letter
def test_stemmer_step1c_y_to_i(_args, assert)
  stemmer = LunrQuery::STEMMER
  assert.equal! stemmer.call('lay'), 'lay'   # 'a' is a vowel, don't replace
  assert.equal! stemmer.call('try'), 'tri'   # 'r' is a consonant, replace
  assert.equal! stemmer.call('by'), 'by'     # 'b' is first letter, don't replace
  assert.equal! stemmer.call('say'), 'say'   # 'a' is a vowel, don't replace
end

def test_stemmer_ational_suffix(_args, assert)
  stemmer = LunrQuery::STEMMER
  assert.equal! stemmer.call('relational'), 'relat'
end

def test_stemmer_ness_suffix(_args, assert)
  stemmer = LunrQuery::STEMMER
  assert.equal! stemmer.call('goodness'), 'good'
end

def test_stemmer_vocabulary(_args, assert)
  vocab = $gtk.parse_json_file('tests/fixtures/stemming_vocab.json')

  stemmer = LunrQuery::STEMMER

  vocab.each do |word, expected|
    result = stemmer.call(word)
    assert.equal! result, expected, "Failed: '#{word}' -> expected '#{expected}', got '#{result}'"
  end
end
