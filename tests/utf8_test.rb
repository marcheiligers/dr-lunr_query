require 'lib/lunr_query/utf8'

def test_utf8_length_ascii(_args, assert)
  assert.equal! LunrQuery::UTF8.length('hello'), 5
end

def test_utf8_length_2byte(_args, assert)
  # 'é' is U+00E9, 2 bytes in UTF-8
  # "café" = 3 ASCII bytes + 2 UTF-8 bytes = 5 bytes, 4 characters
  assert.equal! 'café'.length, 5
  assert.equal! LunrQuery::UTF8.length('café'), 4
end

def test_utf8_length_3byte(_args, assert)
  # 'ⓘ' is U+24D8, 3 bytes in UTF-8
  # "aⓘb" = 2 ASCII + 3 UTF-8 = 5 bytes, 3 characters
  assert.equal! 'aⓘb'.length, 5
  assert.equal! LunrQuery::UTF8.length('aⓘb'), 3
end

def test_utf8_length_empty(_args, assert)
  assert.equal! LunrQuery::UTF8.length(''), 0
end

def test_utf8_slice_ascii(_args, assert)
  assert.equal! LunrQuery::UTF8.slice('hello', 1, 3), 'ell'
end

def test_utf8_slice_2byte(_args, assert)
  assert.equal! LunrQuery::UTF8.slice('café', 0, 3), 'caf'
  assert.equal! LunrQuery::UTF8.slice('café', 3, 1), 'é'
  assert.equal! LunrQuery::UTF8.slice('café', 2, 2), 'fé'
end

def test_utf8_slice_3byte(_args, assert)
  assert.equal! LunrQuery::UTF8.slice('aⓘb', 0, 2), 'aⓘ'
  assert.equal! LunrQuery::UTF8.slice('aⓘb', 1, 1), 'ⓘ'
  assert.equal! LunrQuery::UTF8.slice('aⓘb', 1, 2), 'ⓘb'
end

def test_utf8_slice_past_end(_args, assert)
  assert.equal! LunrQuery::UTF8.slice('café', 2, 100), 'fé'
end

def test_utf8_slice_empty(_args, assert)
  assert.equal! LunrQuery::UTF8.slice('hello', 0, 0), ''
end
