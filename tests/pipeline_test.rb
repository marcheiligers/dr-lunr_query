require 'lib/lunr_query/pipeline.rb'

def test_pipeline_empty(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  assert.equal! pipeline.functions.length, 0
end

def test_pipeline_add_function(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  fn = ->(token) { token.upcase }

  pipeline.add(fn)
  assert.equal! pipeline.functions.length, 1
end

def test_pipeline_run_string_no_op(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  result = pipeline.run_string('hello')

  assert.equal! result, ['hello']
end

def test_pipeline_run_string_with_function(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  fn = ->(token) { token.upcase }

  pipeline.add(fn)
  result = pipeline.run_string('hello')

  assert.equal! result, ['HELLO']
end

def test_pipeline_run_string_chained(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  fn1 = ->(token) { token.upcase }
  fn2 = ->(token) { token + '!' }

  pipeline.add(fn1, fn2)
  result = pipeline.run_string('hello')

  assert.equal! result, ['HELLO!']
end

def test_pipeline_filter_nil(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  fn = ->(token) { nil }

  pipeline.add(fn)
  result = pipeline.run_string('hello')

  assert.equal! result.length, 0
end

def test_pipeline_expand_tokens(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  fn = ->(token) { [token, token.reverse] }

  pipeline.add(fn)
  result = pipeline.run_string('cat')

  assert.equal! result, ['cat', 'tac']
end

def test_pipeline_registered_function(_args, assert)
  LunrQuery::Pipeline.register_function('test_upcase', ->(token) { token.upcase })

  pipeline = LunrQuery::Pipeline.new
  pipeline.add('test_upcase')

  result = pipeline.run_string('hello')
  assert.equal! result, ['HELLO']
end

def test_pipeline_to_json(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  json = pipeline.to_json

  assert.equal! json, []
end

def test_pipeline_load_empty(_args, assert)
  pipeline = LunrQuery::Pipeline.load([])
  assert.equal! pipeline.functions.length, 0
end

def test_pipeline_stopwords_filter(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  pipeline.add('stopWordFilter')

  result = pipeline.run_string('the')
  assert.equal! result.length, 0, "Stopword 'the' should be filtered out"

  result = pipeline.run_string('hello')
  assert.equal! result, ['hello'], "Non-stopword should pass through"
end

def test_pipeline_stopwords_multiple(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  pipeline.add('stopWordFilter')

  # Simulate tokenized input (pipeline processes one token at a time)
  result1 = pipeline.run_string('the')
  result2 = pipeline.run_string('quick')
  result3 = pipeline.run_string('and')
  result4 = pipeline.run_string('brown')

  assert.equal! result1.length, 0, "'the' should be filtered"
  assert.equal! result2, ['quick'], "'quick' should pass"
  assert.equal! result3.length, 0, "'and' should be filtered"
  assert.equal! result4, ['brown'], "'brown' should pass"
end

def test_pipeline_stopwords_case_insensitive(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  pipeline.add('stopWordFilter')

  result1 = pipeline.run_string('THE')
  result2 = pipeline.run_string('The')
  result3 = pipeline.run_string('the')

  assert.equal! result1.length, 0, "Uppercase stopword should be filtered"
  assert.equal! result2.length, 0, "Mixed case stopword should be filtered"
  assert.equal! result3.length, 0, "Lowercase stopword should be filtered"
end

def test_pipeline_stopwords_common_words(_args, assert)
  pipeline = LunrQuery::Pipeline.new
  pipeline.add('stopWordFilter')

  stopwords = ['a', 'an', 'and', 'are', 'as', 'at', 'be', 'but', 'by', 'for',
               'if', 'in', 'is', 'it', 'of', 'on', 'or', 'the', 'to', 'with']

  stopwords.each do |word|
    result = pipeline.run_string(word)
    assert.equal! result.length, 0, "'#{word}' should be filtered as stopword"
  end
end

def test_pipeline_load_with_stopwords(_args, assert)
  pipeline = LunrQuery::Pipeline.load(['stopWordFilter'])

  assert.equal! pipeline.functions.length, 1, "Should have one function"

  result = pipeline.run_string('the')
  assert.equal! result.length, 0, "Loaded stopWordFilter should filter 'the'"
end
