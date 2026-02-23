require 'lib/lunr_query/field_ref.rb'

def test_field_ref_to_string(_args, assert)
  field_ref = LunrQuery::FieldRef.new("123", "title")
  assert.equal! field_ref.to_s, "title/123"
end

def test_field_ref_from_string(_args, assert)
  field_ref = LunrQuery::FieldRef.from_string("title/123")
  assert.equal! field_ref.field_name, "title"
  assert.equal! field_ref.doc_ref, "123"
end

def test_field_ref_from_string_with_joiner_in_doc_ref(_args, assert)
  field_ref = LunrQuery::FieldRef.from_string("title/http://example.com/123")
  assert.equal! field_ref.field_name, "title"
  assert.equal! field_ref.doc_ref, "http://example.com/123"
end

def test_field_ref_from_string_without_joiner(_args, assert)
  raised = false
  begin
    LunrQuery::FieldRef.from_string("docRefOnly")
  rescue => e
    raised = true
  end
  assert.true! raised, "Should raise error when string has no joiner"
end

def test_field_ref_string_caching(_args, assert)
  field_ref = LunrQuery::FieldRef.new("123", "title")
  str1 = field_ref.to_s
  str2 = field_ref.to_s
  # String should be cached (same object)
  assert.equal! str1, str2
end
