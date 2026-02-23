require 'lib/lunr_query/set.rb'

def test_complete_set_contains(_args, assert)
  assert.true! LunrQuery::Set::COMPLETE.contains('foo')
  assert.true! LunrQuery::Set::COMPLETE.contains('bar')
  assert.true! LunrQuery::Set::COMPLETE.contains('anything')
end

def test_empty_set_contains(_args, assert)
  assert.false! LunrQuery::Set::EMPTY.contains('foo')
  assert.false! LunrQuery::Set::EMPTY.contains('bar')
end

def test_populated_set_contains_element(_args, assert)
  set = LunrQuery::Set.new(['foo'])
  assert.true! set.contains('foo')
end

def test_populated_set_does_not_contain_non_element(_args, assert)
  set = LunrQuery::Set.new(['foo'])
  assert.false! set.contains('bar')
end

def test_union_with_complete_set(_args, assert)
  set = LunrQuery::Set.new(['foo'])
  result = LunrQuery::Set::COMPLETE.union(set)
  assert.true! result.contains('foo')
  assert.true! result.contains('bar')
  assert.true! result.contains('anything')
end

def test_union_with_empty_set(_args, assert)
  set = LunrQuery::Set.new(['foo'])
  result = LunrQuery::Set::EMPTY.union(set)
  assert.true! result.contains('foo')
  assert.false! result.contains('bar')
end

def test_union_two_populated_sets(_args, assert)
  set1 = LunrQuery::Set.new(['foo'])
  set2 = LunrQuery::Set.new(['bar'])
  result = set1.union(set2)
  assert.true! result.contains('foo')
  assert.true! result.contains('bar')
  assert.false! result.contains('baz')
end

def test_union_populated_with_empty(_args, assert)
  set = LunrQuery::Set.new(['bar'])
  result = set.union(LunrQuery::Set::EMPTY)
  assert.true! result.contains('bar')
  assert.false! result.contains('baz')
end

def test_union_populated_with_complete(_args, assert)
  set = LunrQuery::Set.new(['bar'])
  result = set.union(LunrQuery::Set::COMPLETE)
  assert.true! result.contains('foo')
  assert.true! result.contains('bar')
  assert.true! result.contains('baz')
end

def test_intersect_with_complete_set(_args, assert)
  set = LunrQuery::Set.new(['foo'])
  result = LunrQuery::Set::COMPLETE.intersect(set)
  assert.true! result.contains('foo')
  assert.false! result.contains('bar')
end

def test_intersect_with_empty_set(_args, assert)
  set = LunrQuery::Set.new(['foo'])
  result = LunrQuery::Set::EMPTY.intersect(set)
  assert.false! result.contains('foo')
end

def test_intersect_no_common_elements(_args, assert)
  set1 = LunrQuery::Set.new(['foo'])
  set2 = LunrQuery::Set.new(['bar'])
  result = set1.intersect(set2)
  assert.false! result.contains('foo')
  assert.false! result.contains('bar')
end

def test_intersect_with_common_elements(_args, assert)
  set1 = LunrQuery::Set.new(['foo'])
  set2 = LunrQuery::Set.new(['foo', 'bar'])
  result = set2.intersect(set1)
  assert.true! result.contains('foo')
  assert.false! result.contains('bar')
end

def test_intersect_populated_with_empty(_args, assert)
  set = LunrQuery::Set.new(['foo'])
  result = set.intersect(LunrQuery::Set::EMPTY)
  assert.false! result.contains('foo')
end

def test_intersect_populated_with_complete(_args, assert)
  set = LunrQuery::Set.new(['foo'])
  result = set.intersect(LunrQuery::Set::COMPLETE)
  assert.true! result.contains('foo')
  assert.false! result.contains('bar')
end
