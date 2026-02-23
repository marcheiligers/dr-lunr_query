require 'lib/lunr_query/vector.rb'

# Helper to create vector from values (not indices)
def vector_from_args(*values)
  vector = LunrQuery::Vector.new
  values.each_with_index do |val, idx|
    vector.insert(idx, val)
  end
  vector
end

def test_magnitude_calculation(_args, assert)
  vector = vector_from_args(4, 5, 6)
  expected = Math.sqrt(77)
  assert.true! (vector.magnitude - expected).abs < 0.0001, "Magnitude calculation failed"
end

def test_dot_product(_args, assert)
  v1 = vector_from_args(1, 3, -5)
  v2 = vector_from_args(4, -2, -1)
  assert.equal! v1.dot(v2), 3
end

def test_similarity_calculation(_args, assert)
  v1 = vector_from_args(1, 3, -5)
  v2 = vector_from_args(4, -2, -1)
  assert.true! (v1.similarity(v2) - 0.5).abs < 0.01, "Similarity should be ~0.5"
end

def test_similarity_with_empty_vector(_args, assert)
  v_empty = LunrQuery::Vector.new
  v1 = vector_from_args(1)
  assert.equal! v_empty.similarity(v1), 0
  assert.equal! v1.similarity(v_empty), 0
end

def test_similarity_with_non_overlapping_vectors(_args, assert)
  v1 = LunrQuery::Vector.new([1, 1])
  v2 = LunrQuery::Vector.new([2, 1])
  assert.equal! v1.similarity(v2), 0
  assert.equal! v2.similarity(v1), 0
end

def test_insert_invalidates_magnitude_cache(_args, assert)
  vector = vector_from_args(4, 5, 6)
  mag1 = vector.magnitude
  expected1 = Math.sqrt(77)
  assert.true! (mag1 - expected1).abs < 0.0001, "Initial magnitude wrong"

  vector.insert(3, 7)
  mag2 = vector.magnitude
  expected2 = Math.sqrt(126)
  assert.true! (mag2 - expected2).abs < 0.0001, "Magnitude after insert wrong"
end

def test_insert_keeps_items_in_index_order(_args, assert)
  vector = LunrQuery::Vector.new
  vector.insert(2, 4)
  vector.insert(1, 5)
  vector.insert(0, 6)
  assert.equal! vector.to_array, [6, 5, 4]
end

def test_insert_fails_on_duplicate(_args, assert)
  vector = vector_from_args(4, 5, 6)
  raised = false
  begin
    vector.insert(0, 44)
  rescue => e
    raised = true
  end
  assert.true! raised, "Should raise error on duplicate index"
end

def test_upsert_invalidates_magnitude_cache(_args, assert)
  vector = vector_from_args(4, 5, 6)
  mag1 = vector.magnitude
  expected1 = Math.sqrt(77)
  assert.true! (mag1 - expected1).abs < 0.0001

  vector.upsert(3, 7)
  mag2 = vector.magnitude
  expected2 = Math.sqrt(126)
  assert.true! (mag2 - expected2).abs < 0.0001
end

def test_upsert_keeps_items_in_index_order(_args, assert)
  vector = LunrQuery::Vector.new
  vector.upsert(2, 4)
  vector.upsert(1, 5)
  vector.upsert(0, 6)
  assert.equal! vector.to_array, [6, 5, 4]
end

def test_upsert_calls_function_on_duplicate(_args, assert)
  vector = vector_from_args(4, 5, 6)
  vector.upsert(0, 4) { |current, passed| current + passed }
  assert.equal! vector.to_array, [8, 5, 6]
end

def test_position_for_index_at_beginning(_args, assert)
  vector = LunrQuery::Vector.new([1, 'a', 2, 'b', 4, 'c', 7, 'd', 11, 'e'])
  assert.equal! vector.position_for_index(0), 0
end

def test_position_for_index_at_end(_args, assert)
  vector = LunrQuery::Vector.new([1, 'a', 2, 'b', 4, 'c', 7, 'd', 11, 'e'])
  assert.equal! vector.position_for_index(20), 10
end

def test_position_for_index_consecutive(_args, assert)
  vector = LunrQuery::Vector.new([1, 'a', 2, 'b', 4, 'c', 7, 'd', 11, 'e'])
  assert.equal! vector.position_for_index(3), 4
end

def test_position_for_index_gap_after(_args, assert)
  vector = LunrQuery::Vector.new([1, 'a', 2, 'b', 4, 'c', 7, 'd', 11, 'e'])
  assert.equal! vector.position_for_index(5), 6
end

def test_position_for_index_gap_before(_args, assert)
  vector = LunrQuery::Vector.new([1, 'a', 2, 'b', 4, 'c', 7, 'd', 11, 'e'])
  assert.equal! vector.position_for_index(6), 6
end

def test_position_for_index_gap_before_and_after(_args, assert)
  vector = LunrQuery::Vector.new([1, 'a', 2, 'b', 4, 'c', 7, 'd', 11, 'e'])
  assert.equal! vector.position_for_index(9), 8
end

def test_position_for_index_duplicate_at_beginning(_args, assert)
  vector = LunrQuery::Vector.new([1, 'a', 2, 'b', 4, 'c', 7, 'd', 11, 'e'])
  assert.equal! vector.position_for_index(1), 0
end

def test_position_for_index_duplicate_at_end(_args, assert)
  vector = LunrQuery::Vector.new([1, 'a', 2, 'b', 4, 'c', 7, 'd', 11, 'e'])
  assert.equal! vector.position_for_index(11), 8
end

def test_position_for_index_duplicate_consecutive(_args, assert)
  vector = LunrQuery::Vector.new([1, 'a', 2, 'b', 4, 'c', 7, 'd', 11, 'e'])
  assert.equal! vector.position_for_index(4), 4
end

def test_to_json_returns_elements(_args, assert)
  vector = LunrQuery::Vector.new([1, 2, 3, 4])
  assert.equal! vector.to_json, [1, 2, 3, 4]
end

def test_construct_from_elements(_args, assert)
  vector = LunrQuery::Vector.new([0, 1, 2, 3, 4, 5])
  assert.equal! vector.to_array, [1, 3, 5]
end
